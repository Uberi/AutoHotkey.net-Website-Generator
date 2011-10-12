#NoEnv

;searches the AutoHotkey forums for scripts posted by a specified forum user
SearchForum(ForumUsername,SearchEnglishForum,SearchGermanForum)
{
 global Cache
 Results := Array()
 If SearchEnglishForum
 {
  For Index, Result In ForumSearch("http://www.autohotkey.com/forum/","",ForumUsername,2) ;search the English AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
    GetTopic(Result), ObjInsert(Results,Result)
  }
 }
 If SearchGermanForum
 {
  For Index, Result In ForumSearch("http://de.autohotkey.com/forum/","",ForumUsername,2) ;search the German AutoHotkey forum for posts by the specified forum user
  {
   If (Result.Author = ForumUsername)
    GetTopic(Result), ObjInsert(Results,Result)
  }
 }
 Return, Results
}

;retrieves information about a given forum topic
GetTopic(ByRef Result)
{
 global Cache
 If ObjHasKey(Cache,Result.URL) ;cache contains topic information
 {
  Topic := Cache[Result.URL]
  If (Topic.Image != "")
   Result.Image := Topic.Image
  If (Topic.Source != "")
   Result.Source := Topic.Source
 }
 Else ;download information from the forum
 {
  Topic := ForumGetTopicInfo(Result.URL)
  Cache[Result.URL] := Object()
  If ObjHasKey(Topic,"Image")
   Result.Image := Topic.Image, Cache[Result.URL].Image := Topic.Image
  If ObjHasKey(Topic,"Source")
   Result.Source := Topic.Source, Cache[Result.URL].Source := Topic.Source
  Cache[Result.URL].Description := Topic.Description
 }
 Result.Description := Topic.Description
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

;generates a unique URL fragment from a title
GenerateURLFragment(Title,UsedFragmentList)
{
 Fragment := RegExReplace(Title,"S)\W")
 If ObjHasKey(UsedFragmentList,Fragment)
 {
  Index := 1
  While, ObjHasKey(UsedFragmentList,Fragment . Index)
   Index ++
  Fragment .= Index
 }
 Return, Fragment
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