ProcessCommandLineParameters()
{
 global
 local ValidParameters, Temp1, Parameter, Position, Option, Value
 ValidParameters := Object("ForumUsername",0,"AutoHotkeyNetUsername",0,"AutoHotkeyNetPassword",0,"ShowGUI",1,"UploadWebsite",1,"SearchEnglishForum",1,"SearchGermanForum",1,"UseCache",1,"Template",0,"SortEntries",1,"OutputDirectory",0,"InlineStylesheet",1,"RelativeLinks",1,"DownloadResources",1) ;a list of parameters and the types they accept (0 for string, 1 for boolean)
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
}

OptionsDialogShow:
Gui, Font, s18 Bold, Arial
Gui, Add, Text, x2 y0 w630 h30 Center, AutoHotkey.net Website Generator

Gui, Font, s8
Gui, Add, GroupBox, x10 y40 w310 h110, Credentials
Gui, Font, Norm
Gui, Add, Text, x20 y60 w160 h20, Forum Username:
Gui, Add, Edit, x180 y60 w130 h20 vForumUsername gEnterUsername, %ForumUsername%
Gui, Add, CheckBox, x20 y90 w290 h20 vUsernamesDiffer gUsernamesDiffer, My AutoHotkey.net username is something different
Gui, Add, Text, x20 y120 w160 h20 vAutoHotkeyNetUsernameLabel Disabled, AutoHotkey.net Username:
Gui, Add, Edit, x180 y120 w130 h20 vAutoHotkeyNetUsername Disabled, %ForumUsername%

Gui, Font, Bold
Gui, Add, GroupBox, x330 y40 w290 h80, Upload
Gui, Font, Norm
Gui, Add, CheckBox, x340 y60 w270 h20 vUploadWebsite gUploadWebsite, Upload website to AutoHotkey.net
Gui, Add, Text, x340 y90 w140 h20 vAutoHotkeyNetPasswordLabel Disabled, AutoHotkey.net Password:
Gui, Add, Edit, x480 y90 w130 h20 vAutoHotkeyNetPassword Disabled Password

Gui, Font, Bold
Gui, Add, GroupBox, x10 y160 w310 h70, Search
Gui, Font, Norm
Gui, Add, CheckBox, x20 y180 w290 h20 vSearchEnglishForum Checked, Search in the English AutoHotkey forums
Gui, Add, CheckBox, x20 y200 w290 h20 vSearchGermanForum Checked, Search in the German AutoHotkey forums

Gui, Font, Bold
Gui, Add, GroupBox, x330 y130 w290 h100, Appearance
Gui, Font, Norm
Gui, Add, Text, x340 y150 w140 h20, Template:

;look for templates in the templates directory
TemplatesList := ""
Loop, %ResourcesPath%\*, 2
 TemplatesList .= A_LoopFileName . "|"

Gui, Add, DropDownList, x480 y150 w130 h20 r15 vTemplate Choose1, % SubStr(TemplatesList,1,-1)
GuiControl, ChooseString, Template, %Template%
Gui, Add, Radio, x340 y180 w270 h20 vSortTime Checked, Sort entries by order updated
Gui, Add, Radio, x340 y200 w270 h20 vSortEntries, Sort entries alphabetically

Gui, Font, Bold
Gui, Add, GroupBox, x10 y240 w610 h90, Behavior
Gui, Font, Norm
Gui, Add, CheckBox, x20 y260 w290 h20 vUseCache Checked, Use page information cache
Gui, Add, CheckBox, x20 y280 w290 h20 vInlineStylesheet, Include stylesheet inline
Gui, Add, CheckBox, x20 y300 w290 h20 vRelativeLinks, Rewrite addresses into relative links if possible
Gui, Add, Text, x340 y260 w90 h20, Output Directory:
Gui, Add, Edit, x430 y260 w150 h20 vOutputDirectory, %OutputDirectory%
Gui, Add, Button, x580 y260 w30 h20 gSelectFolder, ...
Gui, Add, CheckBox, x340 y300 w270 h20 vDownloadResources, Download all resources

Gui, Font, s10 Bold
Gui, Add, Button, x10 y340 w610 h30 gOptionsDialogSubmit Default, Generate Website

Gui, Show, w630 h380, Website Generator
Return

GuiClose:
ExitApp

OptionsDialogSubmit:
Gui, Submit
Gosub, GenerateWebsite
Return

EnterUsername:
GuiControlGet, Temp1,, UsernamesDiffer
If !Temp1
{
 GuiControlGet, Temp1,, ForumUsername
 GuiControl,, AutoHotkeyNetUsername, %Temp1%
}
Return

UsernamesDiffer:
GuiControlGet, Temp1,, UsernamesDiffer
GuiControl, Enable%Temp1%, AutoHotkeyNetUsernameLabel
GuiControl, Enable%Temp1%, AutoHotkeyNetUsername
If !Temp1
{
 GuiControlGet, Temp1,, ForumUsername
 GuiControl,, AutoHotkeyNetUsername, %Temp1%
}
Return

SelectFolder:
Gui, +OwnDialogs
FileSelectFolder, Temp1,, 3, Select an output folder:
If !ErrorLevel
 GuiControl,, OutputDirectory, %Temp1%
Return

UploadWebsite:
GuiControlGet, Temp1,, UploadWebsite
GuiControl, Enable%Temp1%, AutoHotkeyNetPasswordLabel
GuiControl, Enable%Temp1%, AutoHotkeyNetPassword
Return