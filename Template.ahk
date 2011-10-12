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

;wip: cache support

n:=-4
MsgBox % ~n//~0

;initializes resources needed by the templating engine
TemplateInit()
{
 global ForumUsername, Template, TemplateSingleTags, TemplateMatchedTags, TemplateProperties, TemplateScriptProperties, TemplateAttributePattern, TemplateTagPattern
 TemplateSingleTags := Object("ahk_script",Func("TemplateProcessScript")) ;self contained tag
 TemplateMatchedTags := Object("ahk_for_each",Func("TemplateProcessForEach")
  ,"ahk_repeat",Func("TemplateProcessRepeat")
  ,"ahk_if",Func("TemplateProcessIf")) ;matched tag

 ;template properties
 FormatTime, Temp1,, Time
 FormatTime, Temp2,, ShortDate
 TemplateProperties := Object("Author",ForumUsername
  ,"Time",Temp1
  ,"Date",Temp2
  ,"Template",Template)

 ;current script properties
 TemplateScriptProperties := Object()

 ;build up the pattern matching template tags
 TemplateAttributePattern := "\s+([\w-]+)(?:\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s""'``=<>]*)))?" ;pattern matching a single tag attribute
 TemplateTagPattern := "iS)<("
 For Key In TemplateSingleTags
  TemplateTagPattern .= Key . "|" ;insert tag name into the pattern
 For Key In TemplateMatchedTags
  TemplateTagPattern .= Key . "|" ;insert opening and closing tag names into the pattern
 TemplateTagPattern := SubStr(TemplateTagPattern,1,-1) . ")((?:" . TemplateAttributePattern . ")*)\s*>"
}

;parses an HTML template and processes any template tags that are present
TemplatePage(Template)
{
 global TemplateSingleTags, TemplateMatchedTags, TemplateAttributePattern, TemplateTagPattern

 Position := 1, Position1 := 1, Result := "" ;initialize variables
 While, Position := RegExMatch(Template,TemplateTagPattern,Output,Position) ;loop over each opening or closing template HTML tag
 {
  Result .= SubStr(Template,Position1,Position - Position1) ;append the sections of the template between template tags

  Position += StrLen(Output), Position1 := Position ;move past the tag, store the position
  If ObjHasKey(TemplateMatchedTags,Output1) ;tag is to be matched
  {
   MatchedPosition := TemplateMatchTag(Template,Position,Output1,TagContents)
   If (MatchedPosition = 0) ;skip over mismatched tag
    Continue
   Result .= TemplateMatchedTags[Output1](TemplateAttributes(Output2),TagContents)
   Position := MatchedPosition, Position1 := MatchedPosition ;move to the end of the closing tag
  }
  Else ;self contained tag
   Result .= TemplateSingleTags[Output1](TemplateAttributes(Output2)) ;process the template tag
 }
 Return, Result . SubStr(Template,Position1) ;return the resulting page with the last section appended
}

;matches a template tag
TemplateMatchTag(ByRef Template,Position,TagName,ByRef TagContents)
{
 global TemplateAttributePattern
 TagDepth := 1, Position1 := Position
 While, (TagDepth > 0) && (Position := RegExMatch(Template,"iS)<(/?)" . TagName . "(?:" . TemplateAttributePattern . ")*\s*>",Output,Position))
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
TemplateAttributes(Attributes)
{
 global TemplateAttributePattern
 Position := 1, Result := Object() ;initialize variables
 While, Position := RegExMatch(Attributes,TemplateAttributePattern,Output,Position) ;loop over each tag attribute
 {
  Position += StrLen(Output) ;move past the current attribute
  Result[Output1] := (Output2 != "") ? Output2 : ((Output3 != "") ? Output3 : Output4) ;set the attribute in the result object
 }
 Return, Result
}

TemplateProcessScript(This,Attributes)
{
 global TemplateProperties, TemplateScriptProperties
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
 ;look for type filters
 TypeFilter := ""
 If ObjHasKey(Attributes,"Script")
  TypeFilter := "Script"
 Else If ObjHasKey(Attributes,"Library")
  TypeFilter := "Library"

 Result := ""
 UsedFragmentList := Object() ;an object containing all URL fragments generated so far

 ;loop through each script
 For Index, Entry In GetResults(TypeFilter)
 {
  ;prepare the script properties object
  TemplateScriptProperties.Index := Index
  TemplateScriptProperties.Fragment := GenerateURLFragment(Entry.Title,UsedFragmentList)
  TemplateScriptProperties.Title := HTMLEscape(Entry.Title)
  TemplateScriptProperties.Image := HTMLEscape(Entry.Image)
  TemplateScriptProperties.Description := Entry.Description
  TemplateScriptProperties.Topic := HTMLEscape(Entry.URL)
  TemplateScriptProperties.Source := HTMLEscape(Entry.Source)
  Result .= TemplatePage(TagContents)
 }
 TemplateScriptProperties := Object() ;clear the script properties
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

TemplateProcessIf(This,Attributes,TagContents)
{
 global TemplateProperties, TemplateScriptProperties
 For Key In Attributes
 {
  If (ObjHasKey(TemplateProperties,Key) && TemplateProperties[Key] != "") ;key is present and not blank in template properties
   Return, TemplatePage(TagContents)
  If (ObjHasKey(TemplateScriptProperties,Key) && TemplateScriptProperties[Key] != "") ;key is present and not blank in script properties
   Return, TemplatePage(TagContents)
  Return
 }
}

;retrieve the results of searching the forum
GetResults(TypeFilter = "")
{
 global ForumUsername, SearchEnglishForum, SearchGermanForum, SortEntries
 static Results := ""
 If !IsObject(Results)
 {
  Results := SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
  If SortEntries
   Results := SortByTitle(Results)
 }
 If (TypeFilter != "") ;process the script type filter if given
 {
  Filtered := Array()
  For Index, Result In Results
  {
   If (DetectTopicCategory(Result.Title,Result.Description) = TypeFilter)
    ObjInsert(Filtered,Result)
  }
  Return, Filtered
 }
 Return, Results
}