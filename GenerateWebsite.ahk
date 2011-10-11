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

;credentials
ForumUsername := "Uberi"
AutoHotkeyNetUsername := ""
AutoHotkeyNetPassword := ""

;behavior
ShowGUI := 1
UploadWebsite := 0
SearchEnglishForum := 1
SearchGermanForum := 1
UseCache := 1

;appearance
Template := "Picturesque Blue"
SortEntries := 0

;output
OutputDirectory := A_ScriptDir . "\WebPage"
InlineStylesheet := 0
RelativeLinks := 0
DownloadResources := 0

ResourcesPath := A_ScriptDir . "\Resources"

If (AutoHotkeyNetUsername = "") ;set the AutoHotkey.net username if it was not given
 AutoHotkeyNetUsername := ForumUsername

ProcessCommandLineParameters() ;process any command line parameters

If ShowGUI
 ShowOptionsDialog()
Else
 GenerateWebsite()
Return

GenerateWebsite()
{
 global ResourcesPath, Template, TemplatePath, PagePath, StylesheetPath, UseCache, Cache, PageTemplate, Stylesheet
 TemplatePath := ResourcesPath . "\" . Template ;set the path of the template
 PagePath := TemplatePath . "\index.html" ;set the path of the page template
 StylesheetPath := TemplatePath . "\style.css" ;set the path of the stylesheet
 ValidateOptions() ;validate the given options
 If UseCache
 {
  FileRead, Cache, %ResourcesPath%\Cache.txt ;read the page cache
  Cache := ProcessCache(Cache)
 }
 TemplateInit()
 Result := TemplatePage(PageTemplate)

 ;write the page to the output directory
 OutputPagePath := OutputDirectory . "\index.html"
 FileDelete, %OutputPagePath%
 FileAppend, %Result%, %OutputPagePath%

 ;write the stylesheet to the output directory
 OutputStylesheetPath := OutputDirectory . "\style.css"
 FileDelete, %OutputStylesheetPath%
 FileAppend, %Result%, %OutputStylesheetPath%

 ExitApp
}

;searches the AutoHotkey forums for scripts posted by a specified forum user
SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
{
 Results := Array()
 If SearchEnglishForum
 {
  For Index, Result In ForumSearch("http://www.autohotkey.com/forum/","",ForumUsername,2) ;search the English AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
   {
    ;download information about the forum topic, and add the information into the result
    Topic := ForumGetTopicInfo(Result.URL)
    Result.Description := Topic.Description
    If ObjHasKey(Topic,"Image")
     Result.Image := Topic.Image
    If ObjHasKey(Topic,"Source")
     Result.Source := Topic.Source
    ObjInsert(Results,Result)
   }
  }
 }
 If SearchGermanForum
 {
  For Index, Result In ForumSearch("http://de.autohotkey.com/forum/","",ForumUsername,2) ;search the German AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
   {
    ;download information about the forum topic, and add the information into the result
    Topic := ForumGetTopicInfo(Result.URL)
    Result.Description := Topic.Description
    If ObjHasKey(Topic,"Image")
     Result.Image := Topic.Image
    If ObjHasKey(Topic,"Source")
     Result.Source := Topic.Source
    ObjInsert(Results,Result)
   }
  }
 }
 Return, Results
}

ShowObject(ShowObject,Padding = "")
{
 ListLines, Off
 If !IsObject(ShowObject)
 {
  ListLines, On
  Return, ShowObject
 }
 ObjectContents := ""
 For Key, Value In ShowObject
 {
  If IsObject(Value)
   Value := "`n" . ShowObject(Value,Padding . A_Tab)
  ObjectContents .= Padding . Key . ": " . Value . "`n"
 }
 ObjectContents := SubStr(ObjectContents,1,-1)
 If (Padding = "")
  ListLines, On
 Return, ObjectContents
}

ProcessCache(Cache)
{
 Cache := Trim(Cache," `t`n") ;remove leading and trailing whitespace and newlines
 Result := Object()
 Loop, Parse, Cache, `n, %A_Space%`t
 {
  Position := InStr(A_LoopField,"`t"), URL := SubStr(A_LoopField,1,Position - 1), Field := SubStr(A_LoopField,Position + 1) ;extract the URL field
  Entry := Object()
  Position := InStr(Field,"`t"), Entry.Type := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the type field
  Position := InStr(Field,"`t"), Entry.Image := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the image field
  Position := InStr(Field,"`t"), Entry.Download := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the download field
  Entry.Description := Field ;extract the description field
  ObjInsert(Result,URL,Entry) ;add the entry to the cache object
 }
 Return, Result
}

#Include Options.ahk
#Include Forum Functions.ahk
#Include Template.ahk