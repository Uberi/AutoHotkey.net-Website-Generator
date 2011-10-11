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

/*
Search := ForumSearch("","","Uberi",2) ;search the "Scripts & Functions" forum for topics by Uberi

TopicList := ""
For Index, Result In Search
{
 If (Result.Author = "Uberi")
  TopicList .= Result.Title . "`n"
}
MsgBox % TopicList
*/

;searches the AutoHotkey forum and returns the results in the form of an object
ForumSearch(BaseURL = "",Keywords = "",Author = "",ForumIndex = 0,ResultLimit = 0,SearchAny = 0,PreviousDays = 0)
{
 If !ForumIndex ;search all available forums if a specific forum is not specified
  ForumIndex := -1 ;the index representing all available forums is -1
 If (BaseURL = "")
  BaseURL := "http://www.autohotkey.com/forum/"

 URL := BaseURL . "search.php?mode=results"
 POSTData := "search_keywords=" . URLEncode(Keywords) . "&search_terms=" . (SearchAny ? "any" : "all") . "&search_author=" . URLEncode(Author) . "&search_forum=" . (ForumIndex ? ForumIndex : -1) . "&search_time=" . PreviousDays . "&search_fields=all&show_results=topics&return_chars=0&sort_by=0&sort_dir=DESC"

 Result := Array() ;prepare the result array
 Loop
 {
  ;request the search results page
  WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1"), WebRequest.Open("POST",URL)
  WebRequest.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
  WebRequest.Send(POSTData), SearchResult := WebRequest.ResponseText, WebRequest := ""

  If (!ParseSearchResultPage(SearchResult,BaseURL,Result,URL,ResultLimit) || URL = "")
   Break
  Sleep, 3000 ;delay to allow the request to close
 }
 Return, Result
}

;parses a search result page
ParseSearchResultPage(SearchResult,BaseURL,ByRef Result,ByRef NextPage,ResultLimit)
{
 SearchResult := SubStr(SearchResult,InStr(SearchResult," class=""forumline""") + 18) ;trim everything up to the main search results table
 SearchResult := SubStr(SearchResult,InStr(SearchResult,"<tr>") + 5) ;trim past the headers row
 SearchResult := SubStr(SearchResult,InStr(SearchResult,"</tr>") + 5) ;trim off the header row

 ;get a link to the next page if it is present
 NextPage := SubStr(SearchResult,InStr(SearchResult,"<span class=""nav"">") + 18) ;skip to the navigation table
 NextPage := SubStr(NextPage,InStr(NextPage,"<span class=""nav"">") + 18) ;skip to the second span of the navigation table
 NextPage := SubStr(NextPage,1,InStr(NextPage,"</span>") - 1) ;skip to the second span of the navigation table
 If (SubStr(NextPage,-3) = "</a>") ;a link to the next page is present
 {
  NextPage := SubStr(NextPage,InStr(NextPage," href=""",0,0) + 7) ;obtain the rightmost URL, which links to the next page
  NextPage := SubStr(NextPage,1,InStr(NextPage,"""") - 1) ;trim the closing quote mark and any remaining data off of the URL
  NextPage := BaseURL . ConvertEntities(NextPage)
 }
 Else ;at the last page
  NextPage := ""

 SearchResult := SubStr(SearchResult,1,InStr(SearchResult,"</table>") - 1) ;trim everything after the navigation table
 SearchResult := SubStr(SearchResult,1,InStr(SearchResult,"<tr>",0,0) - 1) ;trim off the last row of the table

 If InStr(SearchResult,"<td align=""center"">") ;no results found, error message shown
  Return, 0

 SearchResult := RegExReplace(SearchResult,"iS)<(?:tr|td|img)[^>]*>|\n|\r") ;remove opening table row tags, opening table data tags, and newlines
 StringReplace, SearchResult, SearchResult, </tr>, `n, All ;replace closing table row tags with newlines
 SearchResult := Trim(SearchResult," `t`n") ;trim whitespace and newlines from the beginning and the end
 Loop, Parse, SearchResult, `n, %A_Space%`t ;build an array of search results, trimming whitespace and newlines from the beginning and end
 {
  If (ResultLimit && ObjMaxIndex(Result) >= ResultLimit)
   Return, 0

  RowResult := Object() ;prepare the row result object
  Row := RegExReplace(A_LoopField,"iS)<(?:span|/span|br)[^>]*>") ;remove opening and closing span tags and line break tags
  StringReplace, Row, Row, </td>, `n, All ;replace closing table data tags with newlines
  Row := Trim(Row," `t`n") ;trim whitespace and newlines from the beginning and the end
  StringSplit, Field, Row, `n, %A_Space%`t ;split the row into separate fields

  RegExMatch(Field1,"iS) href=""([^""]+)""",Output) ;find the forum URL
  RowResult.Forum := BaseURL . ConvertEntities(Output1) ;forum the topic is located in
  RegExMatch(Field2,"iS) href=""([^""]+)""[^>]*>([^<]*)<",Output) ;find the topic URL and topic title
  RowResult.URL := BaseURL . ConvertEntities(Output1) ;URL of the topic
  RowResult.Title := ConvertEntities(Output2) ;title of the topic
  RegExMatch(Field3,"iS)<a href=""([^""]+)""[^>]*>([^<]*)<",Output) ;find the profile URL and author name
  RowResult.Profile := BaseURL . ConvertEntities(Output1) ;profile of the author
  RowResult.Author := ConvertEntities(Output2) ;username of the author
  RowResult.Replies := Field4 ;number of reply posts
  RowResult.Views := Field5 ;number of times the topic was viewed

  ;remove the "sid" parameter from fields that contain links, as it causes issues with retrieval
  RowResult.Forum := RegExReplace(RowResult.Forum,"iS)[&]sid=\w+")
  RowResult.URL := RegExReplace(RowResult.URL,"iS)[&]sid=\w+")
  RowResult.Profile := RegExReplace(RowResult.Profile,"iS)[&]sid=\w+")
  NextPage := RegExReplace(NextPage,"iS)[&]sid=\w+")

  ObjInsert(Result,RowResult)
 }
 Return, 1
}

;retrieves information about a given forum topic
ForumGetTopicInfo(URL)
{
 WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1"), WebRequest.Open("GET",URL)
 WebRequest.Send(), ForumTopic := WebRequest.ResponseText, WebRequest := ""

 Result := Object()

 ;extract the title of the topic
 Title := SubStr(ForumTopic,InStr(ForumTopic,"<title>") + 7) ;trim up to the topic title
 Title := SubStr(Title,1,InStr(Title,"</title>") - 1) ;trim off everything after the topic title
 Result.Title := Title ;set the title field of the result

 ;extract the author of the topic
 RegExMatch(ForumTopic,"iS)<span class=""name"">.*?<b>([^<]*)</b>",Output) ;match the author field
 Result.Author := Output1

 ;extract the first post of the topic
 ForumTopic := SubStr(ForumTopic,InStr(ForumTopic,"<span class=""postbody"">") + 23) ;trim up to the contents of the first post
 ForumTopic := SubStr(ForumTopic,1,InStr(ForumTopic," class=""row1""") - 1) ;trim everything after the row immediately below the first post

 ;remove the signature if present
 Position := InStr(ForumTopic,"_________________",1,0) ;find a series of underscores, starting from the right
 If Position ;signature block found
  ForumTopic := SubStr(ForumTopic,1,Position - 1) ;trim the signature off of the end of the post

 ;extract a description of the topic
 Temp1 := SubStr(ForumTopic,1,InStr(ForumTopic,"<br ") - 1) ;extract the first paragraph of the post
 Temp1 := ConvertEntities(Temp1) ;convert any HTML entities present into their literal equivelants
 StringReplace, Temp1, Temp1, `r,, All ;remove all carriage returns
 StringReplace, Temp1, Temp1, `n,, All ;remove all newlines
 Temp1 := Trim(Temp1) ;remove leading and trailing whitespace
 Temp1 := RegExReplace(Temp1,"S)\.\K[^\.<>]+:$") ;if the last sentence ends with a colon, and there are sentences before it, remove the last sentence
 Temp1 := RegExReplace(Temp1,"S)^[^\.]*\K:$",".") ;if the description ends with a colon, and contains only one sentence, replace the colon with a period
 If (SubStr(Temp1,0) != ".") ;insert a period at the end of the description if one is not present
  Temp1 .= "."
 Temp1 := RegExReplace(Temp1,"iS)<a\s.*?href=""([^""]*)""[^>]*>([^<]+)</a>","<> href=""$1"" class=""link"">$2</>") ;normalize hyperlinks and temporarily change them into invalid tags ;wip: if this is a link to a topic, search the topic result list and link to another place in the generated website?
 Temp1 := RegExReplace(Temp1,"iS)<(?!/?>)[^>]*>") ;remove any HTML tags excluding hyperlinks that are still present
 StringReplace, Temp1, Temp1, <>, <a, All ;return opening hyperlink tags to their original form
 StringReplace, Temp1, Temp1, </>, </a>, All ;return closing hyperlink tags to their original form
 Result.Description := Temp1 ;set the description field of the result

 ;extract an image if present
 If RegExMatch(ForumTopic,"iS)<img\s.*?src=""([^""]*)""",Output)
  Result.Image := Output1 ;set the image field of the result

 ;extract a download link if present
 If RegExMatch(ForumTopic,"iS)<a\s.*?href=""([^""]*\.(?:ahk|exe))""[^>]*>[\w\s\.-]+</a>",Output)
  Result.Source := Output1 ;set the image field of the result

 Return, Result
}

;detects the category of a given topic
DetectTopicCategory(Title,Description) ;wip: allow user definitions with regex
{
 LibraryKeywords := "Library,Function,Lib,Funktionen"
 If Title Contains %LibraryKeywords%
  Return, "Library"
 If Description Contains %LibraryKeywords%
  Return, "Library"
 Return, "Script"
}

URLEncode(URL)
{
 StringReplace, URL, URL, `%, `%25, All
 FormatInteger := A_FormatInteger, FoundPos := 0
 SetFormat, IntegerFast, Hex
 While, (FoundPos := RegExMatch(URL,"iS)[^\w-\.~%]",Char,FoundPos + 1))
  StringReplace, URL, URL, %Char%, % "%" . SubStr("0" . SubStr(Asc(Char),3),-1), All
 SetFormat, IntegerFast, %FormatInteger%
 Return, URL
}

ConvertEntities(HTML)
{
 static EntityList := "|quot=34|apos=39|amp=38|lt=60|gt=62|nbsp=160|iexcl=161|cent=162|pound=163|curren=164|yen=165|brvbar=166|sect=167|uml=168|copy=169|ordf=170|laquo=171|not=172|shy=173|reg=174|macr=175|deg=176|plusmn=177|sup2=178|sup3=179|acute=180|micro=181|para=182|middot=183|cedil=184|sup1=185|ordm=186|raquo=187|frac14=188|frac12=189|frac34=190|iquest=191|Agrave=192|Aacute=193|Acirc=194|Atilde=195|Auml=196|Aring=197|AElig=198|Ccedil=199|Egrave=200|Eacute=201|Ecirc=202|Euml=203|Igrave=204|Iacute=205|Icirc=206|Iuml=207|ETH=208|Ntilde=209|Ograve=210|Oacute=211|Ocirc=212|Otilde=213|Ouml=214|times=215|Oslash=216|Ugrave=217|Uacute=218|Ucirc=219|Uuml=220|Yacute=221|THORN=222|szlig=223|agrave=224|aacute=225|acirc=226|atilde=227|auml=228|aring=229|aelig=230|ccedil=231|egrave=232|eacute=233|ecirc=234|euml=235|igrave=236|iacute=237|icirc=238|iuml=239|eth=240|ntilde=241|ograve=242|oacute=243|ocirc=244|otilde=245|ouml=246|divide=247|oslash=248|ugrave=249|uacute=250|ucirc=251|uuml=252|yacute=253|thorn=254|yuml=255|OElig=338|oelig=339|Scaron=352|scaron=353|Yuml=376|circ=710|tilde=732|ensp=8194|emsp=8195|thinsp=8201|zwnj=8204|zwj=8205|lrm=8206|rlm=8207|ndash=8211|mdash=8212|lsquo=8216|rsquo=8217|sbquo=8218|ldquo=8220|rdquo=8221|bdquo=8222|dagger=8224|Dagger=8225|hellip=8230|permil=8240|lsaquo=8249|rsaquo=8250|euro=8364|trade=8482|"
 FoundPos := 1
 While, (FoundPos := InStr(HTML,"&",1,FoundPos))
 {
  FoundPos ++, Entity := SubStr(HTML,FoundPos,InStr(HTML,";",1,FoundPos) - FoundPos), (SubStr(Entity,1,1) = "#") ? (EntityCode := SubStr(Entity,2)) : (Temp1 := InStr(EntityList,"|" . Entity . "=") + StrLen(Entity) + 2, EntityCode := SubStr(EntityList,Temp1,InStr(EntityList,"|",1,Temp1) - Temp1))
  StringReplace, HTML, HTML, &%Entity%`;, % Chr(EntityCode), All
 }
 Return, HTML
}

HTMLEscape(String)
{
 Transform, Escaped, HTML, %String%
 Return, Escaped
}