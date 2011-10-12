#NoEnv

;wip: allow templating css files

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
 global ResourcesPath, TemplatePath, OutputPath, Template, UseCache, Cache

 TemplatePath := ExpandPath(ResourcesPath . "\" . Template) ;set the path of the template

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
 PathLength := StrLen(TemplatePath) + 1
 Loop, %TemplatePath%\*,, 1
 {
  TempOutput := OutputPath . SubStr(A_LoopFileFullPath,PathLength)
  If (A_LoopFileExt = "htm" || A_LoopFileExt = "html") ;page template ;wip: configurable extensions
  {
   FileRead, PageTemplate, %A_LoopFileLongPath%
   Result := TemplatePage(PageTemplate)
   FileDelete, %TempOutput%
   FileAppend, %Result%, %TempOutput%
  }
  Else ;other file type, can simply copy to output directory
   FileCopy, %A_LoopFileLongPath%, %TempOutput%, 1
 }

 ;save cache if needed
 If UseCache
 {
  FileDelete, %CachePath%
  FileAppend, % SaveCache(Cache), %CachePath%
 }
}

#Include Options.ahk
#Include Utility.ahk
#Include Forum Functions.ahk
#Include Template.ahk