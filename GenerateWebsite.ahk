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
InlineStylesheet := 0
RelativeLinks := 0
DownloadResources := 0

;wip: show progress in the GUI only if ShowGUI is in effect, otherwise remain silent

ResourcesDirectory := A_ScriptDir . "\Resources"
If (AutoHotkeyNetUsername = "") ;set the AutoHotkey.net username if it was not given
 AutoHotkeyNetUsername := ForumUsername

Gosub, ProcessCommandLine
If ShowGUI
{
 Gosub, OptionsDialogShow
 Return
}
Gosub, ValidateOptions
Gosub, GenerateWebsite
ExitApp

#Include Options Dialog.ahk

GenerateWebsite:
ListVars
MsgBox
Return

ValidateOptions:
If !InStr(FileExist(OutputDirectory),"D") ;output directory does not exist
{
 MsgBox, 16, Error, Invalid output directory:`n`n"%OutputDirectory%"
 ExitApp, 1
}
Temp1 := ResourcesDirectory . "\Styles\" . Stylesheet . ".css"
FileRead, PageStyle, %Temp1% ;read the stylesheet
If (ErrorLevel || InStr(FileExist(Temp1),"D")) ;stylesheet does not exist or is a directory instead of a file
{
 MsgBox, 16, Error, Invalid stylesheet:`n`n"%Stylesheet%"
 ExitApp, 1
}
Return

ProcessCommandLine:
ValidParameters := Object("ForumUsername",0,"AutoHotkeyNetUsername",0,"AutoHotkeyNetPassword",0,"ShowGUI",1,"UploadWebsite",1,"SearchEnglishForum",1,"SearchGermanForum",1,"UseCache",1,"Stylesheet",0,"SortPages",1,"OutputDirectory",0,"InlineStylesheet",1,"RelativeLinks",1,"DownloadResources",1) ;a list of parameters and the types they accept (0 for string, 1 for boolean)
Loop, %0% ;loop through each command line parameter in the form "--OPTION=VALUE"
{
 Parameter := %A_Index%
 If (SubStr(Parameter,1,2) != "--") ;parameters must begin with "--"
 {
  MsgBox, 16, Error, Invalid command line parameter given:`n`n"%Parameter%"
  ExitApp, 1
 }
 Temp1 := SubStr(Parameter,3), Position := InStr(Temp1,"=")
 If !Position ;could not find "="
 {
  MsgBox, 16, Error, Option is missing value:`n`n"%Parameter%"
  ExitApp, 1
 }
 Option := SubStr(Temp1,1,Position - 1), Value := SubStr(Temp1,Position + 1)
 If !ObjHasKey(ValidParameters,Option)
 {
  MsgBox, 16, Error, Unknown option:`n`n"%Parameter%"
  ExitApp, 1
 }
 If ValidParameters[Option] ;parameter is a boolean flag
 {
  If (Value = "True")
   Value := 1
  Else If (Value = "False")
   Value := 0
  Else
   Value := !!Value
 }
 %Option% := Value
}
Return