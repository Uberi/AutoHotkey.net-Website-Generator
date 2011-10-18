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
 If !DllCall("wininet\FtpCreateDirectory","UInt",hConnection,UPtr,&Directory)
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