#NoEnv

;wip: logging and nested directories in templates

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

;upload
UploadWebsite := 0
AutoHotkeyNetPassword := ""

;search
SearchEnglishForum := 1
SearchGermanForum := 1

;appearance
Template := "Picturesque Blue"
SortEntries := 0

;behavior
ShowGUI := 1
UseCache := 1
RelativeLinks := 1
DownloadResources := 0 ;wip: not implemented yet

;output
OutputPath := A_ScriptDir . "\WebPage"

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
 global ResourcesPath, TemplatePath, OutputPath, Template, UseCache, Cache, UploadWebsite

 ;process paths
 If !InStr(FileExist(OutputPath),"D") ;output directory does not exist
  OutputError("Invalid output directory: " . OutputPath,1)
 OutputPath := ExpandPath(OutputPath) ;expand the path of the output
 TemplatePath := ResourcesPath . "\" . Template
 If !InStr(FileExist(TemplatePath),"D") ;template directory does not exist
  OutputError("Invalid template: " . Template,1)
 TemplatePath := ExpandPath(TemplatePath) ;set the path of the template

 ;open cache if needed
 If UseCache
 {
  CachePath := ResourcesPath . "\Cache.txt"
  FileRead, Cache, %CachePath% ;read the page cache
  Cache := ReadCache(Cache)
 }
 Else
  Cache := Object() ;return a blank cache object

 ;open an AutoHotkey.net upload session if needed
 If (UploadWebsite && AutoHotkeySiteOpenSession()) ;upload option set and failed to open session
 {
  OutputError("Could not open uploading session with AutoHotkey.net. The program will continue without uploading.")
  UploadWebsite := 0 ;disable uploading since session opening failed
 }

 ;process page template
 TemplateInit()
 PathLength := StrLen(TemplatePath) + 1 ;store the base path length
 Loop, %TemplatePath%\*,, 1
 {
  OutputSubpath := SubStr(A_LoopFileFullPath,PathLength + 1) ;obtain the relative path
  TempOutput := OutputPath . "\" . OutputSubpath ;obtain the path of the corresponding file in the output

  ;handle nonexistant subdirectories in the output directory
  SplitPath, TempOutput,, Temp1 ;obtain the directory of the current file in the output
  If !InStr(FileExist(Temp1),"D") ;the directory could not be found
  {
   FileCreateDir, %Temp1% ;create the directory
   If ErrorLevel
    OutputError("Could not create folder: " . Temp1)
   If (UploadWebsite && AutoHotkeySiteCreateDirectory(Temp1)) ;upload option set and directory creation failed
    OutputError("Could not create directory: " . Temp1)
  }

  If (A_LoopFileExt = "htm" || A_LoopFileExt = "html" || A_LoopFileExt = "css") ;templatable file
  {
   FileRead, PageTemplate, %A_LoopFileLongPath%
   Result := TemplatePage(PageTemplate) ;run file contents through the template engine
   FileDelete, %TempOutput%
   FileAppend, %Result%, %TempOutput%
  }
  Else ;other file type
   FileCopy, %A_LoopFileLongPath%, %TempOutput%, 1 ;copy directly to the output directory
  If ErrorLevel
    OutputError("Could not write file: " . TempOutput)

  ;process uploading if needed
  If (UploadWebsite && AutoHotkeySiteUpload(TempOutput,OutputSubpath)) ;upload option set and file upload failed ;wip: create the folder if it doesn't exist
   OutputError("Could not upload file: " . TempOutput)
 }

 If (UploadWebsite && AutoHotkeySiteCloseSession())
  OutputError("Could not close uploading session.")

 ;save cache if needed
 If UseCache
 {
  FileDelete, %CachePath%
  FileAppend, % SaveCache(Cache), %CachePath%
 }
}

;detects the category of a given topic
DetectTopicCategory(Title,Description)
{
 LibraryKeywords := "Library,Function,Lib,Funktionen"
 If Title Contains %LibraryKeywords%
  Return, "Library"
 If Description Contains %LibraryKeywords%
  Return, "Library"
 Return, "Script"
}

;converts links to script forum topics to webpage references
MakeRelativeLinks(ByRef Results)
{
 ;map each topic URL to its corresponding result index
 URLMap := Object()
 For Index, Result In Results
  RegExMatch(Result.URL,"iS)/topic\K\d+",TopicID), URLMap[TopicID] := Index

 ;convert links in result descriptions
 For Index, Result In Results ;iterate through each result
 {
  Description := Result.Description, Description1 := "", Position := 1, Position1 := 1 ;initialize variables
  While, Position := RegExMatch(Description,"iS)(<a[^>]+href="")([^""]*)""",Output,Position) ;loop through each hyperlink
  {
   Description1 .= SubStr(Description,Position1,Position - Position1) ;append text between hyperlinks
   Position += StrLen(Output), Position1 := Position ;move positions past hyperlink
   If (RegExMatch(Output2,"iS)/forum/viewtopic.php\?t=\K\d+",TopicID) && ObjHasKey(URLMap,TopicID)) ;is a forum topic URL, and is a link to a previously found topic result
    Description1 .= Output1 . "#" . Results[URLMap[TopicID]].Fragment . """" ;append the link relative to the site
   Else ;is not a forum script topic link
    Description1 .= Output ;directly append the link
  }
  Result.Description := Description1 . SubStr(Description,Position1) ;set the description to the processed result
 }
}

#Include Options.ahk
#Include Utility.ahk
#Include AutoHotkey Site.ahk
#Include Forum Functions.ahk
#Include Template.ahk