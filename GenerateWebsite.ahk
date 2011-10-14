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
DownloadResources := 0

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
 global ResourcesPath, TemplatePath, OutputPath, FileTemplatePattern, Template, UseCache, Cache

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
  If (A_LoopFileExt = "htm" || A_LoopFileExt = "html" || A_LoopFileExt = "css") ;templatable file, process template tags
  {
   FileRead, PageTemplate, %A_LoopFileLongPath%
   Result := TemplatePage(PageTemplate)
   FileDelete, %TempOutput%
   FileAppend, %Result%, %TempOutput%
  }
  Else ;other file type, can copy to output directory
   FileCopy, %A_LoopFileLongPath%, %TempOutput%, 1
 }

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

;retrieve the results of searching the forum
GetResults(TypeFilter = "")
{
 global ForumUsername, SearchEnglishForum, SearchGermanForum, SortEntries, RelativeLinks
 static Results := ""
 If !IsObject(Results)
 {
  Results := SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)

  ;add URL fragments to each result
  UsedFragmentList := Object() ;an object containing all URL fragments generated so far
  For Index, Result In Results
   Result.Fragment := GenerateURLFragment(Result.Title,UsedFragmentList)

  If RelativeLinks
   MakeRelativeLinks(Results)

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
#Include Forum Functions.ahk
#Include Template.ahk