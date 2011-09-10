#NoEnv

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
Stylesheet := "Blue"
SortPages := 0

;output
OutputDirectory := A_ScriptDir . "\WebPage"
InlineCSS := 0
RelativeLinks := 0
DownloadResources := 0

;wip: show progress in the GUI

If (AutoHotkeyNetUsername = "") ;set the AutoHotkey.net username if it was not given
 AutoHotkeyNetUsername := ForumUsername

Gosub, ProcessCommandLine
Return

ProcessCommandLine:
ValidParameters := Object("ForumUsername","","AutoHotkeyNetUsername","","AutoHotkeyNetPassword","","ShowGUI","","UploadWebsite","","SearchEnglishForum","","SearchGermanForum","","UseCache","","Stylesheet","","SortPages","","OutputDirectory","","InlineCSS","","RelativeLinks","","DownloadResources","")
Loop, %0% ;loop through each command line parameter in the form "--OPTION=VALUE"
{
 Parameter := %A_Index%
 If (SubStr(Parameter,1,2) != "--") ;parameters must begin with "--"
 {
  MsgBox, 16, Error, Invalid command line parameter given:`n`n"%Parameter%"
  ExitApp, 1
 }
 CurrentParameter := SubStr(Parameter,3), Position := InStr(CurrentParameter,"=")
 If !Position ;could not find "="
 {
  MsgBox, 16, Error, Option is missing value:`n`n"%Parameter%"
  ExitApp, 1
 }
 Option := SubStr(CurrentParameter,1,Position - 1), Value := SubStr(CurrentParameter,Position + 1)
 If !ObjHasKey(ValidParameters,Option)
 {
  MsgBox, 16, Error, Unknown option:`n`n"%Parameter%"
  ExitApp, 1
 }
 %Option% := Value
}
Return