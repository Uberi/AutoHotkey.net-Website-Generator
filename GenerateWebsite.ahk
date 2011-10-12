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

#Include Options.ahk
#Include Utility.ahk
#Include Forum Functions.ahk
#Include Template.ahk