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
OutputPath := A_ScriptDir . "\WebPage"
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
{
 GenerateWebsite()
 ExitApp
}
Return

GenerateWebsite()
{
 global ResourcesPath, OutputPath, Template, TemplatePath, PagePath, StylesheetPath, UseCache, Cache, PageTemplate, Stylesheet
 TemplatePath := ResourcesPath . "\" . Template ;set the path of the template
 PagePath := TemplatePath . "\index.html" ;set the path of the page template
 StylesheetPath := TemplatePath . "\style.css" ;set the path of the stylesheet
 ValidateOptions() ;validate the given options

 ;read cache if needed
 If UseCache
 {
  CachePath := ResourcesPath . "\Cache.txt"
  FileRead, Cache, %CachePath% ;read the page cache
  Cache := ReadCache(Cache)
 }
 Else
  Cache := Object()

 ;process page template
 TemplateInit()
 Result := TemplatePage(PageTemplate)

 ;save cache if needed
 If UseCache
 {
  FileDelete, %CachePath%
  FileAppend, % SaveCache(Cache), %CachePath%
 }

 ;write the page to the output directory
 OutputPagePath := OutputPath . "\index.html"
 FileDelete, %OutputPagePath%
 FileAppend, %Result%, %OutputPagePath%

 ;write the stylesheet to the output directory
 OutputStylesheetPath := OutputPath . "\style.css"
 FileDelete, %OutputStylesheetPath%
 FileAppend, %Stylesheet%, %OutputStylesheetPath%
}

;searches the AutoHotkey forums for scripts posted by a specified forum user
SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
{
 global Cache
 Results := Array()
 If SearchEnglishForum
 {
  For Index, Result In ForumSearch("http://www.autohotkey.com/forum/","",ForumUsername,2) ;search the English AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
    GetTopic(Result), ObjInsert(Results,Result)
  }
 }
 If SearchGermanForum
 {
  For Index, Result In ForumSearch("http://de.autohotkey.com/forum/","",ForumUsername,2) ;search the German AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
    GetTopic(Result), ObjInsert(Results,Result)
  }
 }
 Return, Results
}

;retrieves information about a given forum topic
GetTopic(ByRef Result)
{
 global Cache
 If ObjHasKey(Cache,Result.URL) ;cache contains topic information
 {
  Topic := Cache[Result.URL]
  If (Topic.Image != "")
   Result.Image := Topic.Image
  If (Topic.Source != "")
   Result.Source := Topic.Source
 }
 Else ;download information from the forum
 {
  Topic := ForumGetTopicInfo(Result.URL)
  If ObjHasKey(Topic,"Image")
   Result.Image := Topic.Image
  If ObjHasKey(Topic,"Source")
   Result.Source := Topic.Source
 }
 Result.Description := Topic.Description
}

ReadCache(Cache)
{
 Cache := Trim(Cache," `t`n") ;remove leading and trailing whitespace and newlines
 Result := Object()
 Loop, Parse, Cache, `n, %A_Space%`t ;loop through each cache entry
 {
  Position := InStr(A_LoopField,"`t"), URL := SubStr(A_LoopField,1,Position - 1), Field := SubStr(A_LoopField,Position + 1) ;extract the URL field
  Entry := Object()
  Position := InStr(Field,"`t"), Entry.Image := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the image field
  Position := InStr(Field,"`t"), Entry.Source := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the source field
  Entry.Description := Field ;extract the description field
  ObjInsert(Result,URL,Entry) ;add the entry to the cache object
 }
 Return, Result
}

SaveCache(Cache)
{
 Result := ""
 For URL, Entry In Cache
  Result .= URL . "`t" . Entry.Image . "`t" . Entry.Source . "`t" . Entry.Description . "`n"
 Return, SubStr(Result,1,-1)
}

#Include Options.ahk
#Include Forum Functions.ahk
#Include Template.ahk