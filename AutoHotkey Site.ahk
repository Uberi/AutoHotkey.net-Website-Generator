;opens an FTP session with AutoHotkey.net
AutoHotkeySiteOpenSession()
{
 global AutoHotkeyNetUsername, AutoHotkeyNetPassword, hWinINet, hInternet, hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 hWinINet := DllCall("LoadLibrary","Str","wininet.dll")
 hInternet := DllCall("wininet\InternetOpen","Str","AutoHotkey","UInt",0,"UInt",0,"UInt",0,"UInt",0)
 If !hInternet
  Return, 1
 hConnection := DllCall("wininet\InternetConnect","UInt",hInternet,"Str","autohotkey.net","UInt",21,UPtr,&AutoHotkeyNetUsername,UPtr,&AutoHotkeyNetPassword,"UInt",1,"UInt",0,"UInt",0)
 If !hConnection
  Return, 1
 Return, 0
}

;uploads a file to AutoHotkey.net
AutoHotkeySiteUpload(LocalFile,RemoteFile)
{
 global hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 If !DllCall("wininet\FtpPutFile","UInt",hConnection,UPtr,&LocalFile,UPtr,&RemoteFile,"UInt",0,"UInt",0)
  Return, 1
 Return, 0
}

;creates a directory at AutoHotkey.net
AutoHotkeySiteCreateDirectory(Directory)
{
 global hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 If !DllCall("wininet\FtpCreateDirectory","UInt",hConnection,UPtr,&Directory) ;wip: not sure about return value
  Return, 1
 Return, 0
}

;closes the previously opened FTP session
AutoHotkeySiteCloseSession()
{
 global hWinINet, hInternet, hConnection
 UPtr := A_PtrSize ? "UPtr" : "UInt"
 If !DllCall("wininet\InternetCloseHandle","UInt",hConnection)
  Return, 1
 If !DllCall("wininet\InternetCloseHandle","UInt",hInternet)
  Return, 1
 DllCall("FreeLibrary",UPtr,hWinINet)
 Return, 0
}