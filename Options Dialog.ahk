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
Gui, Add, Text, x340 y90 w160 h20 vAutoHotkeyNetPasswordLabel Disabled, AutoHotkey.net Password:
Gui, Add, Edit, x500 y90 w110 h20 vAutoHotkeyNetPassword Disabled Password

Gui, Font, Bold
Gui, Add, GroupBox, x10 y160 w310 h70, Search
Gui, Font, Norm
Gui, Add, CheckBox, x20 y180 w290 h20 vSearchEnglishForum Checked, Search in the English AutoHotkey forums
Gui, Add, CheckBox, x20 y200 w290 h20 vSearchGermanForum Checked, Search in the German AutoHotkey forums

Gui, Font, Bold
Gui, Add, GroupBox, x330 y130 w290 h100, Appearance
Gui, Font, Norm
Gui, Add, Text, x340 y150 w160 h20, Stylesheet:

;look for styles in the resources directory
StylesList := ""
Loop, %ResourcesDirectory%\Styles\*.css
{
 SplitPath, A_LoopFileName,,,, Temp1
 StylesList .= Temp1 . "|"
}

Gui, Add, DropDownList, x500 y150 w110 h20 r15 vStylesheet Choose1, % SubStr(StylesList,1,-1)
Gui, Add, Radio, x340 y180 w270 h20 vSortTime Checked, Sort entries by order updated
Gui, Add, Radio, x340 y200 w270 h20 vSortPages, Sort entries alphabetically

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
Gosub, ValidateOptions
Gosub, GenerateWebsite
ExitApp

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
FileSelectFolder, Temp1,, 6, Select an output folder:
GuiControl,, OutputDirectory, %Temp1%
Return

UploadWebsite:
GuiControlGet, Temp1,, UploadWebsite
GuiControl, Enable%Temp1%, AutoHotkeyNetPasswordLabel
GuiControl, Enable%Temp1%, AutoHotkeyNetPassword
Return