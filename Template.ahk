#NoEnv

Template = 
(
<html>
 <head>
  <title>This is a title</title>
 </head>
 <body><ahk_repeat>
  <p><span>Hello</span>, World!</p>
  <ahk_author>
  <ahk_for_each Script Attrib>Test <ahk_script_index></ahk_for_each>
 </ahk_repeat></body>
</html>
)
MsgBox % TemplatePage(Template)
ExitApp

n:=-4
MsgBox % ~n//~0

TemplatePage(Template)
{
 TemplateTags := Object("ahk_author",Object("Matched",0
   ,"Process",Func("TemplateProcessAuthor"))
  ,"ahk_script_index",Object("Matched",0
   ,"Process",Func("TemplateProcessIndex"))
  ,"ahk_for_each",Object("Matched",1
   ,"Process",Func("TemplateProcessForEach"))
  ,"ahk_repeat",Object("Matched",1
   ,"Process",Func("TemplateProcessRepeat")))

 ;build up the pattern matching template tags
 AttributePattern := "\s+([\w-]+)(?:\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s""'``=<>]*)))?"
 TagPattern := "iS)<("
 For Key, Value In TemplateTags
  TagPattern .= (Value.Matched ? "/?" : "") . Key . "|" ;insert tag names to the pattern, as well as the closing tag pattern if necessary
 TagPattern := SubStr(TagPattern,1,-1) . ")((?:" . AttributePattern . ")*)\s*>"

 Stack := Array(), StackIndex := 0 ;initialize stack
 Position := 1, Position1 := 1, Result := "", ResultPosition := 0 ;initialize variables
 While, Position := RegExMatch(Template,TagPattern,Output,Position) ;loop over each opening or closing template HTML tag
 {
  Result .= SubStr(Template,Position1,Position - Position1) ;append the sections of the template between template tags
  ResultPosition += Position - Position1 ;update the current position within the length

  Position += StrLen(Output), Position1 := Position ;move past the tag, store the position
  If (SubStr(Output1,1,1) = "/") ;closing HTML tag
  {
   Output1 := SubStr(Output1,2) ;trim the slash from the beginning of the string

   ;handle mismatched tags by searching the stack for the opening tag and closing any opened tags above the found entry, or skipping over the closing tag if that fails
   SearchIndex := StackIndex
   While, SearchIndex > 0 && Output1 != Stack[SearchIndex].TagName ;iterate through each currently open tag
    SearchIndex -- ;close the tag, lower the index to search
   If (SearchIndex = 0) ;tag matching by searching the stack failed
    Continue ;skip over mismatched tag

   While, StackIndex >= SearchIndex ;add closing tags
   {
    Temp1 := Stack[StackIndex].Position ;retrieve the position of the matching opening tag
    TagContents := SubStr(Result,Temp1 + 1,ResultPosition - Temp1) ;retrieve the contents of the tag
    TagContents := TemplateTags[Output1].Process(TemplateAttributes(Stack[StackIndex].Attributes,AttributePattern),TagContents) ;process the template tag
    Result := SubStr(Result,1,Temp1) . TagContents, ResultPosition := Temp1 + StrLen(TagContents) ;insert the processed result into the processed page
    ObjRemove(Stack,StackIndex,""), StackIndex -- ;pop the tag from the stack
   }
  }
  Else If TemplateTags[Output1].Matched ;tag is to be matched
    StackIndex ++, Stack[StackIndex] := Object("TagName",Output1,"Attributes",Output2,"Position",ResultPosition) ;push the tag, its attributes, and the current position in the result onto the stack
  Else ;self contained tag
  {
   TagContents := TemplateTags[Output1].Process(TemplateAttributes(Output2,AttributePattern))
   Result .= TagContents, ResultPosition += StrLen(TagContents) ;process the template tag
  }
 }
 Return, Result . SubStr(Template,Position1) ;return the resulting page with the last section appended
}

TemplateAttributes(Attributes,AttributePattern)
{
 Position := 1 ;initialize variables
 Result := Object()
 While, Position := RegExMatch(Attributes,AttributePattern,Output,Position) ;loop over each tag attribute
 {
  Position += StrLen(Output)
  Result[Output1] := (Output2 != "") ? Output2 : ((Output3 != "") ? Output3 : Output4)
 }
 Return, Result
}

TemplateProcessAuthor(This,Attributes)
{
 Return, "[Uberi]"
}

TemplateProcessIndex(This,Attributes)
{
 Return, 1
}

TemplateProcessForEach(This,Attributes,TagContents)
{
 Return, "{" . TagContents . "}"
}

TemplateProcessRepeat(This,Attributes,TagContents)
{
 Return, "{repeat " . Attributes.Times . " times: " . TagContents . "}"
}