#NoEnv

OutputError(ErrorText,Fatal = 0)
{
 global ShowGUI
 If ShowGUI
  MsgBox, 16, Error, %ErrorText% ;display the error
 Else
  FileAppend, %ErrorText%`n, * ;write the error text to standard output
 If Fatal ;unrecoverable error
  ExitApp, 1
}

;parses a given cache into a cache object
ReadCache(Cache)
{
 Cache := Trim(Cache," `t`n") ;remove leading and trailing whitespace and newlines
 Result := Object()
 Loop, Parse, Cache, `n, %A_Space%`t ;loop through each cache entry
 {
  Entry := Object()
  Position := InStr(A_LoopField,"`t"), URL := SubStr(A_LoopField,1,Position - 1), Field := SubStr(A_LoopField,Position + 1) ;extract the URL field
  Position := InStr(Field,"`t"), Entry.Image := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the image field
  Position := InStr(Field,"`t"), Entry.Source := SubStr(Field,1,Position - 1), Field := SubStr(Field,Position + 1) ;extract the source field
  Entry.Description := Field ;extract the description field
  ObjInsert(Result,URL,Entry) ;add the entry to the cache object
 }
 Return, Result
}

;converts a cache object into the cache file format
SaveCache(Cache)
{
 Result := ""
 For URL, Entry In Cache
  Result .= URL . "`t" . Entry.Image . "`t" . Entry.Source . "`t" . Entry.Description . "`n"
 Return, SubStr(Result,1,-1)
}

;sorts an array of results by title
SortByTitle(InputObject)
{
 ;merge sort algorithm
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

;converts a path into an absolute path
ExpandPath(Path)
{
 Loop, %Path%, 2
  Return, A_LoopFileLongPath
}