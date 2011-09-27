#NoEnv

n:=5
MsgBox % ~n//~0

TemplatePage(Template)
{
 TemplateTags := Object("ahk_author",Func("TemplateGetAuthor"),"ahk_script_type",Func("TemplateGetScriptType"),"ahk_for_each_script","")
}

TemplateGetAuthor()
{
 global ForumUsername
 Return, ForumUsername
}

TemplateGetScriptType()
{
 ;wip
}