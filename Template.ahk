#NoEnv

#Warn All
#Warn LocalSameAsGlobal, Off

/*
Copyright 2011 Anthony Zhang <azhang9@gmail.com>

This file is part of AutoHotkey.net Website Generator. Source code is available at <https://github.com/Uberi/AutoHotkey.net-Website-Generator>.

AutoHotkey.net Website Generator is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

Template = 
(
<html>
 <head>
  <title>This is a title</title>
 </head>
 <body>
  <ahk_repeat 2><p><span><ahk_repeat 3>Hello</ahk_repeat></span>, World!</p>
  <ahk_script Author>
  <ahk_for_each>Test <ahk_script Index></ahk_for_each>
 </ahk_repeat></body>
</html>
)
MsgBox % TemplatePage(Template)
ExitApp

n:=-4
MsgBox % ~n//~0

;parses an HTML template and processes any template tags that are present
TemplatePage(Template)
{
 SingleTemplateTags := Object("ahk_script",Func("TemplateProcessScript"))
 MatchedTemplateTags := Object("ahk_for_each",Func("TemplateProcessForEach")
  ,"ahk_repeat",Func("TemplateProcessRepeat"))

 ;build up the pattern matching template tags
 AttributePattern := "\s+([\w-]+)(?:\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s""'``=<>]*)))?" ;pattern matching a single tag attribute
 TagPattern := "iS)<("
 For Key In SingleTemplateTags
  TagPattern .= Key . "|" ;insert tag name into the pattern
 For Key In MatchedTemplateTags
  TagPattern .= Key . "|" ;insert opening and closing tag names into the pattern
 TagPattern := SubStr(TagPattern,1,-1) . ")((?:" . AttributePattern . ")*)\s*>"

 Stack := Array(), StackIndex := 0, Position := 1, Position1 := 1, Result := "" ;initialize variables
 While, Position := RegExMatch(Template,TagPattern,Output,Position) ;loop over each opening or closing template HTML tag
 {
  Result .= SubStr(Template,Position1,Position - Position1) ;append the sections of the template between template tags

  Position += StrLen(Output), Position1 := Position ;move past the tag, store the position
  If ObjHasKey(MatchedTemplateTags,Output1) ;tag is to be matched
  {
   MatchedPosition := TemplateMatchTag(Template,Position,Output1,AttributePattern,TagContents)
   If (MatchedPosition = 0) ;skip over mismatched tag
    Continue
   Result .= MatchedTemplateTags[Output1](TemplateAttributes(Output2,AttributePattern),TagContents)
   Position := MatchedPosition, Position1 := MatchedPosition ;move to the end of the closing tag
  }
  Else ;self contained tag
   Result .= SingleTemplateTags[Output1](TemplateAttributes(Output2,AttributePattern)) ;process the template tag
 }
 Return, Result . SubStr(Template,Position1) ;return the resulting page with the last section appended
}

;matches a template tag
TemplateMatchTag(ByRef Template,Position,TagName,AttributePattern,ByRef TagContents)
{
 TagDepth := 1, Position1 := Position
 While, (TagDepth > 0) && (Position := RegExMatch(Template,"iS)<(/?)" . TagName . "(?:" . AttributePattern . ")*\s*>",Output,Position))
 {
  Position += StrLen(Output)
  If (Output1 = "") ;opening tag
   TagDepth ++
  Else ;closing tag
   TagDepth --
 }
 If (TagDepth > 0) ;tag could not be matched
  Return, 0
 TagContents := SubStr(Template,Position1,Position - (Position1 + StrLen(Output)))
 Return, Position
}

;parses the template tag attributes into an object
TemplateAttributes(Attributes,AttributePattern)
{
 Position := 1, Result := Object() ;initialize variables
 While, Position := RegExMatch(Attributes,AttributePattern,Output,Position) ;loop over each tag attribute
 {
  Position += StrLen(Output) ;move past the current attribute
  Result[Output1] := (Output2 != "") ? Output2 : ((Output3 != "") ? Output3 : Output4) ;set the attribute in the result object
 }
 Return, Result
}

TemplateProcessScript(This,Attributes)
{
 global TemplateScriptProperties
 TemplateProperties := Object("Author","Uberi") ;wip: use ForumUsername here
 For Key In Attributes
 {
  If ObjHasKey(TemplateProperties,Key)
   Return, TemplateProperties[Key]
  If ObjHasKey(TemplateScriptProperties,Key)
   Return, TemplateScriptProperties[Key]
 }
}

TemplateProcessForEach(This,Attributes,TagContents)
{
 global TemplateScriptProperties
 Result := ""
 ;For Index In GetResults()
 {
  TemplateScriptProperties := Object("Index",A_Index
   ,"Fragment","<_ahk Fragment>"
   ,"Title","<_ahk Title>"
   ,"Image","<_ahk Image>"
   ,"Description","<_ahk Description>"
   ,"Topic","<_ahk Topic>"
   ,"Source","<_ahk Source>")
  Result .= TemplatePage(TagContents)
 }
 Return, Result
}

TemplateProcessRepeat(This,Attributes,TagContents)
{
 RepeatCount := 1, Result := ""
 For Key In Attributes
 {
  If Key Is Integer
  {
   RepeatCount := Key
   Break
  }
 }
 Loop, %RepeatCount%
  Result .= TemplatePage(TagContents)
 Return, Result
}

/*
;retrieve the results of searching the forum
GetResults(TypeFilter = "")
{
 global ForumUsername, SearchEnglishForum, SearchGermanForum
 static Results
 If !IsObject(Results)
 {
  Results := SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
  If SortEntries
   Results := SortByTitle(Results)
 }
 If (TypeFilter != "") ;process the script type filter if given
 {
  Filtered := Object()
  For Index, Result In Results
  {
   If (DetectTopicCategory(Result.Title,Result.Description) = TypeFilter) ;wip: these fields are not available until the topic itself is parsed
    ObjInsert(Filtered,Result)
  }
  Return, Filtered
 }
 Return, Result
}

;sorts an array of results by title
SortByTitle(InputObject)
{
 MaxIndex := ObjMaxIndex(InputObject), (MaxIndex = "") ? (MaxIndex := 0) : ""
 If (MaxIndex < 2)
  Return, InputObject
 Middle := MaxIndex >> 1, SortLeft := Object(), SortRight := Object()
 Loop, %Middle%
  ObjInsert(SortLeft,InputObject[A_Index]), ObjInsert(SortRight,InputObject[Middle + A_Index])
 If (MaxIndex & 1)
  ObjInsert(SortRight,InputObject[MaxIndex])
 SortLeft := SortByTitle(SortLeft), SortRight := SortByTitle(SortRight), MaxRight := MaxIndex - Middle, LeftIndex := 1, RightIndex := 1, Result := Object()
 Loop, %MaxIndex%
 {
  If (LeftIndex > Middle)
   ObjInsert(Result,SortRight[RightIndex]), RightIndex ++
  Else If ((RightIndex > MaxRight) || (SortLeft[LeftIndex].Title < SortRight[RightIndex].Title))
   ObjInsert(Result,SortLeft[LeftIndex]), LeftIndex ++
  Else
   ObjInsert(Result,SortRight[RightIndex]), RightIndex ++
 }
 Return, Result
}