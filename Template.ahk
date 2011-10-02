#NoEnv

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
  <ahk_repeat><p><span>Hello</span>, World!</p>
  <ahk_author>
  <ahk_for_each>Test <ahk_script_index></ahk_for_each>
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
 TemplateTags := Object("ahk_script",Object("Matched",0
   ,"Process",Func("TemplateProcessScript"))
  ,"ahk_for_each",Object("Matched",1
   ,"Process",Func("TemplateProcessForEach"))
  ,"ahk_repeat",Object("Matched",1
   ,"Process",Func("TemplateProcessRepeat")))

 ;build up the pattern matching template tags
 AttributePattern := "\s+([\w-]+)(?:\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s""'``=<>]*)))?"
 TagPattern := "iS)<("
 For Key, Value In TemplateTags
  TagPattern .= (Value.Matched ? "/?" : "") . Key . "|" ;insert tag names to the pattern, as well as the closing tag pattern if necessary
 TagPattern := SubStr(TagPattern,1,-1) . ")((?:" . AttributePattern . ")*)\s*>"

 Stack := Array(), StackIndex := 0 ;initialize stack
 Position := 1, Position1 := 1, Result := "", ResultPosition := 0 ;initialize variables
 While, Position := RegExMatch(Template,TagPattern,Output,Position) ;loop over each opening or closing template HTML tag
 {
  Result .= SubStr(Template,Position1,Position - Position1) ;append the sections of the template between template tags
  ResultPosition += Position - Position1 ;update the current position within the length

  Position += StrLen(Output), Position1 := Position ;move past the tag, store the position
  If (SubStr(Output1,1,1) = "/") ;closing HTML tag
  {
   Output1 := SubStr(Output1,2) ;trim the slash from the beginning of the string

   ;handle mismatched tags by searching the stack for the opening tag and closing any opened tags above the found entry, or skipping over the closing tag if that fails
   SearchIndex := StackIndex
   While, SearchIndex > 0 && Output1 != Stack[SearchIndex].TagName ;iterate through each currently open tag
    SearchIndex -- ;close the tag, lower the index to search
   If (SearchIndex = 0) ;tag matching by searching the stack failed
    Continue ;skip over mismatched tag

   While, StackIndex >= SearchIndex ;add closing tags
   {
    Temp1 := Stack[StackIndex].Position ;retrieve the position of the matching opening tag
    TagContents := SubStr(Result,Temp1 + 1,ResultPosition - Temp1) ;retrieve the contents of the tag
    TagContents := TemplateTags[Output1].Process(TemplateAttributes(Stack[StackIndex].Attributes,AttributePattern),TagContents) ;process the template tag
    Result := SubStr(Result,1,Temp1) . TagContents, ResultPosition := Temp1 + StrLen(TagContents) ;insert the processed result into the processed page
    ObjRemove(Stack,StackIndex,""), StackIndex -- ;pop the tag from the stack
   }
  }
  Else If TemplateTags[Output1].Matched ;tag is to be matched
    StackIndex ++, Stack[StackIndex] := Object("TagName",Output1,"Attributes",Output2,"Position",ResultPosition) ;push the tag, its attributes, and the current position in the result onto the stack
  Else ;self contained tag
  {
   TagContents := TemplateTags[Output1].Process(TemplateAttributes(Output2,AttributePattern))
   Result .= TagContents, ResultPosition += StrLen(TagContents) ;process the template tag
  }
 }
 Return, Result . SubStr(Template,Position1) ;return the resulting page with the last section appended
}

;parses the template tag attributes into an object
TemplateAttributes(Attributes,AttributePattern)
{
 Position := 1 ;initialize variables
 Result := Object()
 While, Position := RegExMatch(Attributes,AttributePattern,Output,Position) ;loop over each tag attribute
 {
  Position += StrLen(Output) ;move past the current attribute
  Result[Output1] := (Output2 != "") ? Output2 : ((Output3 != "") ? Output3 : Output4) ;set the attribute in the result object
 }
 Return, Result
}

TemplateProcessScript(This,Attributes)
{
 global ForumUsername
 ScriptProperties := Object("Author",ForumUsername
  ,"Fragment","<_ahk Fragment>"
  ,"Title","<_ahk Title>"
  ,"Image","<_ahk Image>"
  ,"Description","<_ahk Description>"
  ,"Topic","<_ahk Topic>"
  ,"Source","<_ahk Source>")
 For Key In Attributes
 {
  If ObjHasKey(ScriptProperties,Key)
   Return, ScriptProperties[Key]
 }
}

TemplateProcessIndex(This,Attributes)
{
 Return, 1
}

TemplateProcessForEach(This,Attributes,TagContents)
{
 Result := ""
 For Index In GetResults()
  Result .= TagContents
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
  Result .= TagContents
 Return, Result
}

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