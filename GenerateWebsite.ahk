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
Template := "Picturesque Green"
SortEntries := 0

;output
OutputDirectory := A_ScriptDir . "\WebPage"
InlineStylesheet := 0
RelativeLinks := 0
DownloadResources := 0

;wip: show progress in the GUI only if ShowGUI is in effect, otherwise remain silent
;wip: autogenerated help message available from the GUI and the command line

ResourcesPath := A_ScriptDir . "\Resources"

If (AutoHotkeyNetUsername = "") ;set the AutoHotkey.net username if it was not given
 AutoHotkeyNetUsername := ForumUsername

ProcessCommandLineParameters() ;process any command line parameters

If ShowGUI
 Gosub, OptionsDialogShow
Else
 Gosub, GenerateWebsite
Return

GenerateWebsite:
TemplatePath := ResourcesPath . "\" . Template ;set the path of the template
PagePath := TemplatePath . "\index.html" ;set the path of the page template
StylesheetPath := TemplatePath . "\style.css" ;set the path of the stylesheet
Gosub, ValidateOptions
Results := SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
If UseCache
{
 FileRead, Cache, %ResourcesPath%\Cache.txt ;read the page cache
 Cache := ProcessCache(Cache)
}
If SortEntries
 Results := SortByTitle(Results)
For Index, Result In Results
{
 ;wip: do something with the results here
}
ExitApp

;searches the AutoHotkey forums for scripts posted by a specified forum user
SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
{
 Results := Array()
 If SearchEnglishForum
 {
  For Index, Result In ForumSearch("http://www.autohotkey.com/forum/","",ForumUsername,2) ;search the English AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
    ObjInsert(Results,Result)
  }
 }
 If SearchGermanForum
 {
  For Index, Result In ForumSearch("http://de.autohotkey.com/forum/","",ForumUsername,2) ;search the German AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
    ObjInsert(Results,Result)
  }
 }
 Return, Results
}

;sorts an array of results by title
SortByTitle(InputObject)
{
 MaxIndex := ObjMaxIndex(InputObject), (MaxIndex = "") ? (MaxIndex := 0) : ""
 If (MaxIndex < 2)
  Return, InputObject
 Middle := MaxIndex >> 1, SortLeft := Object(), SortRight := Object()
 Loop, %Middle%
  ObjInsert(SortLeft,InputObject[A_Index]), ObjInsert(SortRight,InputObject[Middle + A_Index])
 If (MaxIndex & 1)
  ObjInsert(SortRight,InputObject[MaxIndex])
 SortLeft := SortByTitle(SortLeft), SortRight := SortByTitle(SortRight), MaxRight := MaxIndex - Middle, LeftIndex := 1, RightIndex := 1, Result := Object()
 Loop, %MaxIndex%
 {
  If (LeftIndex > Middle)
   ObjInsert(Result,SortRight[RightIndex]), RightIndex ++
  Else If ((RightIndex > MaxRight) || (SortLeft[LeftIndex].Title < SortRight[RightIndex].Title))
   ObjInsert(Result,SortLeft[LeftIndex]), LeftIndex ++
  Else
   ObjInsert(Result,SortRight[RightIndex]), RightIndex ++
 }
 Return, Result
}

ValidateOptions:
If !InStr(FileExist(OutputDirectory),"D") ;output directory does not exist
{
 MsgBox, 16, Error, Invalid output directory:`n`n"%OutputDirectory%"
 ExitApp, 1
}

If !InStr(FileExist(TemplatePath),"D") ;output directory does not exist
{
 MsgBox, 16, Error, Invalid template:`n`n"%Template%"
 ExitApp, 1
}

FileRead, Stylesheet, %StylesheetPath% ;read the stylesheet
If ErrorLevel ;stylesheet could not be read
{
 MsgBox, 16, Error, Could not find stylesheet:`n`n"%StylesheetPath%"
 ExitApp, 1
}

FileRead, PageTemplate, %PagePath% ;read the stylesheet
If ErrorLevel ;stylesheet could not be read
{
 MsgBox, 16, Error, Could not find page template:`n`n"%PagePath%"
 ExitApp, 1
}
Return

ShowObject(ShowObject,Padding = "")
{
 ListLines, Off
 If !IsObject(ShowObject)
 {
  ListLines, On
  Return, ShowObject
 }
 ObjectContents := ""
 For Key, Value In ShowObject
 {
  If IsObject(Value)
   Value := "`n" . ShowObject(Value,Padding . A_Tab)
  ObjectContents .= Padding . Key . ": " . Value . "`n"
 }
 ObjectContents := SubStr(ObjectContents,1,-1)
 If (Padding = "")
  ListLines, On
 Return, ObjectContents
}

ProcessCache(Cache)
{
 Cache := Trim(Cache," `t`n") ;remove leading and trailing whitespace and newlines
 Result := Object()
 Loop, Parse, Cache, `n, %A_Space%`t
 {
  Position := InStr(A_LoopField,"`t"), URL := SubStr(A_LoopField,1,Position - 1), Field := SubStr(A_LoopField,Position + 1) ;extract the URL field
  Entry := Object()
  Position := InStr(Field,"`t"), Entry.Type := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the type field
  Position := InStr(Field,"`t"), Entry.Image := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the image field
  Position := InStr(Field,"`t"), Entry.Download := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the download field
  Entry.Description := Field ;extract the description field
  ObjInsert(Result,URL,Entry) ;add the entry to the cache object
 }
 Return, Result
}

#Include Options.ahk
#Include Forum Functions.ahk
#Include Template.ahk