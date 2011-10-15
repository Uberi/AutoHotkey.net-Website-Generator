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
 global ResourcesPath, TemplatePath, OutputPath, Template, UseCache, Cache, UploadWebsite, AutoHotkeyNetUsername, AutoHotkeyNetPassword

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

 ;open an AutoHotkey.net upload session if needed
 If (UploadWebsite && AutoHotkeySiteOpenSession()) ;upload option set and failed to open session
 {
   ;wip: error here
   MsgBox
   UploadWebsite := 0 ;disable uploading since session opening failed
 }

 ;process page template
 TemplateInit()
 PathLength := StrLen(TemplatePath) + 1
 Loop, %TemplatePath%\*,, 1
 {
  OutputSubpath := SubStr(A_LoopFileFullPath,PathLength + 1)
  TempOutput := OutputPath . "\" . OutputSubpath
  If (A_LoopFileExt = "htm" || A_LoopFileExt = "html" || A_LoopFileExt = "css") ;templatable file, process template tags
  {
   FileRead, PageTemplate, %A_LoopFileLongPath%
   Result := TemplatePage(PageTemplate)
   FileDelete, %TempOutput%
   FileAppend, %Result%, %TempOutput%
  }
  Else ;other file type, can copy to output directory
   FileCopy, %A_LoopFileLongPath%, %TempOutput%, 1

  ;process uploading
  If (UploadWebsite && AutoHotkeySiteUpload(TempOutput,OutputSubpath)) ;upload option set and file upload failed ;wip: create the folder if it doesn't exist
  {
   ;wip: error here
   MsgBox
  }
 }

 If (UploadWebsite && AutoHotkeySiteCloseSession())
 {
  ;wip: error here
  MsgBox
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

;opens an FTP session with AutoHotkey.net
AutoHotkeySiteOpenSession()
{
 global AutoHotkeyNetUsername, AutoHotkeyNetPassword, hWinINet, hInternet, hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 hWinINet := DllCall("LoadLibrary","Str","wininet.dll")
 hInternet := DllCall("wininet\InternetOpen","Str","AutoHotkey","UInt",0,"UInt",0,"UInt",0,"UInt",0)
 If !hInternet
  Return, 1
 hConnection := DllCall("wininet\InternetConnect","UInt",hInternet,"Str","autohotkey.net","UInt",21,UPtr,&AutoHotkeyNetUsername,UPtr,&AutoHotkeyNetPassword,"UInt",1,"UInt",0,"UInt",0)
 If !hConnection
  Return, 1
 Return, 0
}

;uploads a file to AutoHotkey.net
AutoHotkeySiteUpload(LocalFile,RemoteFile)
{
 global hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 If !DllCall("wininet\FtpPutFile","UInt",hConnection,UPtr,&LocalFile,UPtr,&RemoteFile,"UInt",0,"UInt",0)
  Return, 1
 Return, 0
}

;closes the previously opened FTP session
AutoHotkeySiteCloseSession()
{
 global hWinINet, hInternet, hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 If !DllCall("wininet\InternetCloseHandle","UInt",hConnection)
  Return, 1
 If !DllCall("wininet\InternetCloseHandle","UInt",hInternet)
  Return, 1
 DllCall("FreeLibrary",UPtr,hWinINet)
 Return, 0
}

#Include Options.ahk
#Include Utility.ahk
#Include Forum Functions.ahk
#Include Template.ahk