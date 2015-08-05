;
;ScratchpadPlus
;Author:		scott@bitwise.ninja
;Website:		http://dreamcyclestudios.com

; Based on 

;Scratchpad
;Author:		Desi Quintans <me@desiquintans.com>
;Website:		http://www.desiquintans.com/scratchpad

;
;Script Function:
;	Scratchpad is a quick-and-dirty note-taking tool with a minimum of frills, meant to show
;	up when you need it and get out of the way when you don't. Programmers can use it to
;	document code changes as they happen without having an extra program on their taskbar, or
;	you could use it to store snippets of text temporarily.
;

#include SCI.ahk

#NoEnv
#Persistent
#SingleInstance, Force
#MaxHotkeysPerInterval, 200
SendMode Input
FileEncoding UTF-8
SetWorkingDir %A_ScriptDir%
OnExit, SaveOnExit

Gui +LastFound
GUI1 := WinExist()

Menu,Tray, NoStandard
Menu, Tray, Add, Show/Hide, GuiShowHide
Menu, Tray, Add
Menu, Tray, Default, Show/Hide
Menu, Tray, Click, 1
Menu, Tray, Standard

LastActiveFile =
RecordedLastModified =
DefaultWindowTitle = ScratchpadPlus
UnsavedWindowTitle = ScratchpadPlus *

OnMessage(0x112,"WM_SYSCOMMAND")

Gui,+AlwaysOnTop +Resize +MinSize500x582y

if 0 > 0 ;If a command-line parameter (%0%) has been passed to the exe
{
	if 1 = "/min"
	{
		Gui, Show, Hide h582 w466, %DefaultWindowTitle%
	}
}
else
{
	IfExist, ScratchpadPlusData.ini
	{
		IniRead, minimisedStatus, ScratchpadData.ini, Settings, StartMinimised
		
		if minimisedStatus = 1
		{
			Gui, Show, Hide h640 w500, %DefaultWindowTitle%
		}
		else
		{
			Gui, Show, h640 w500, %DefaultWindowTitle%
		}
	}
	else
	{
		Gui, Show, h640 w500, %DefaultWindowTitle%
	}
}

	; All this stuff is up here so that it's not affected by the font change. Easier
	; to do it like this than to change the font again.
	Gui, Add, GroupBox, x22 y445 w420 h75 , 
		Gui, Add, Text, x32 y463 w60 h20 , Current file:
		Gui, Add, Edit, x92 y460 w340 h20 vHistory ReadOnly -Background c808080, Unknown file
		Gui, Add, CheckBox, x32 y490 w130 h20 checked vSaveOnExit gUpdateVars, Autosave on exit
		Gui, Add, CheckBox, x162 y490 w130 h20 vStartMinimised gUpdateVars, Start minimised
		Gui, Add, Button, x310 y487 w122 h26 gNew, New From Template
	
	Gui, Add, GroupBox, x22 y524 w420 h40 , 	
		Gui, Add, Edit, x32 y537 w320 h20 -WantReturn vGuiMessage -0x100 gSearch
		Gui, Add, Button, x+10 y537 gSearchAgain, Search Again
		
	Gui, Add, GroupBox, x22 y564 w290 h40 , 
		Gui, Add, Text, x32 y580 w100 h20 , Show/Hide Hotkey:
		Gui, Add, Hotkey, x135 y577 w110 h20 vVisibilityHotkey gSetBind, s
		Gui, Add, CheckBox, x252 y572 w40 h30 checked vUseWinkey gUpdateVars, Win

	Gui, Add, Button, x444 y580 w20 h20 gHelp, ?
		
	gui, font, s8, DejaVu Sans
	Gui, Color, B0C4DE

	sci:= new scintilla
	sci.Notify := "SCI_NOTIFY"
	sci.Add(WinExist(), x, y, 500,440, DllPath, "WS_BORDER") ; emtpy variables will make the wrapper use the default values
	sci.StyleSetFont(32, "Office Code Pro Medium"), sci.StyleSetSize(32, 7) ; Font settings
	sci.StyleSetFont(33, "Office Code Pro Medium"), sci.StyleSetSize(33, 7) ; Font settings
	
	sci.StyleSetFore(SCE_AHKL_USERDEFINED1, 0xEE0000), sci.StyleSetBold(SCE_AHKL_USERDEFINED1, true)

	sci.SetLexer(SCLEX_CONTAINER)
	sci.SetStyling(10, STYLE_DEFAULT)
	sci.SetMarginWidthN(0, 40) ; Line number
	sci.SetMarginWidthN(1, 10) ; Foldemargin
	dci.SetMarginWidthN(2, 15)
	sci.SetTabWidth(4)
	sci.SetIndentationGuides(3)
	sci.SetMarginMaskN(1, SC_MASK_FOLDERS )	
	sci.SetMarginSensitiveN(1, true)
	sci.SetFoldMarginColour(0x00FF00)
	sci.SetWrapMode(true)

	sci.MarkerDefine(SC_MARKNUM_FOLDER, SC_MARK_BOXPLUS)
	sci.MarkerDefine(SC_MARKNUM_FOLDEROPEN, SC_MARK_BOXMINUS)
	sci.MarkerDefine(SC_MARKNUM_FOLDERSUB, SC_MARK_VLINE)
	sci.MarkerDefine(SC_MARKNUM_FOLDERTAIL, SC_MARK_LCORNER)
	sci.MarkerDefine(SC_MARKNUM_FOLDEREND, SC_MARK_BOXPLUSCONNECTED)
	sci.MarkerDefine(SC_MARKNUM_FOLDEROPENMID, SC_MARK_BOXMINUSCONNECTED)
	sci.MarkerDefine(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_TCORNER)
	sci.SetSelBack(1,0x81c0ff)
	sci.SetCaretFore(0xFF0000)

	sci.StyleSetFore(STYLE_LINENUMBER , 0x9d9e9f)
	sci.StyleSetBack(STYLE_LINENUMBER , 0x35434d)

	sci.GrabFocus()
	
	GuiControl, Focus, Text

	GoSub, ReadFromIni
	GoSub, SetBind
	GoSub, LoadOnStart
	GoSub, UpdateVars
Return

GuiSize:
WinMove, % "ahk_id " sci.hwnd,, 5, 5, % a_guiwidth - 10, 
return

Help:
WinSet, AlwaysOnTop, Off
MsgBox, 32, Help — ScratchpadPlus,
(
Ctrl+S		Save
Ctrl+Shift+S	Save As
Ctrl+O		Open
Ctrl+N		New file from template
		(template/template.txt)

Escape		Hide ScratchpaPlus (if it's active)
Show/Hide key	Toggle ScratchpadPlus's visibility

Note: Autosaving creates a backup in the same folder as the current file.
Scratchpad also refreshes the active file (if necessary) whenever you unhide it.

You are using ScratchpadPlus v1, released 13 Au 2013.

desiquintans.com/scratchpad
dreamcyclestudios.com
)
WinSet, AlwaysOnTop, On
return

#IfWinActive, ScratchpadPlus ahk_class AutoHotkeyGUI
	Escape::Gosub, GuiHideOnly
	+^s::GoSub, SaveAs
	^s::GoSub, Save
	^o::GoSub, Open
	^n::GoSub, New
	Pause::
		WinSet, AlwaysOnTop, Off
		GuiControlGet,dropdown,,History
		
		MsgBox, LastActiveFile: %LastActiveFile%`nHistory: %dropdown%
		WinSet, AlwaysOnTop, On
	return

#IfWinActive ; Undoes the context-sensitivity from above.

SetBind:
	Gui, Submit, NoHide

	if UseWinKey = 1
		AccessKey := "#" VisibilityHotkey
	else
		AccessKey = VisibilityHotkey
	
	if WinkeyStatus_old = 1
	{
		AccessKey_old := "#" AccessKey_old
		Hotkey,%AccessKey_old%, GuiShowHide, off UseErrorLevel
	}
	else
	{
		Hotkey,%AccessKey_old%, GuiShowHide, off UseErrorLevel
	}
	
	Hotkey,%AccessKey%, GuiShowHide, on UseErrorLevel
	
	AccessKey_old := VisibilityHotkey
	WinkeyStatus_old := UseWinkey
	
	GoSub, UpdateVars
	GuiControl, Focus, Text
Return

Search:
    Gui, Submit, Nohide
    
    if !GuiMessage  ; If search box is empty clear all positions to start from the beginning again.
        pos := newpos := 0
        
    ; Clear old matches
    sci.StartStyling(0, 0x1f)
    sci.SetStyling(sci.GetLength()+1, STYLE_DEFAULT)
    
    ; Find and style new match
    sci.StartStyling(pos:=Search(sci, newpos ? newpos : 0, sci.GetLength()+1, GuiMessage), 0x1f) ; 0x1f sets text bits styles, no indicators.
    sci.SetStyling(strlen(GuiMessage), SCE_AHKL_USERDEFINED1), sci.GoToPos(pos) ; Change color of length of typed text to style #1, move caret to position.
    
    sci.ScrollCaret() ; scroll in to view.
return

F3::
SearchAgain:
    ; sets position forward to allow searching for next match
    newpos := pos + strlen(GuiMessage)
    GoSub, Search
return

WriteToIni:
	IfExist, ScratchpadPlusData.ini
		FileDelete, ScratchpadPlusData.ini

	IniWrite, %SaveOnExit%, ScratchpadPlusData.ini, Settings, SaveOnExit
	IniWrite, %StartMinimised%, ScratchpadPlusData.ini, Settings, StartMinimised
	IniWrite, %VisibilityHotkey%, ScratchpadPlusData.ini, Settings, VisibilityHotkey
	IniWrite, %UseWinkey%, ScratchpadPlusData.ini, Settings, UseWinkey
	IniWrite, %LastActiveFile%, ScratchpadPlusData.ini, Settings, LastActiveFile
	
	WinGetPos, WinX, WinY,,,ScratchpadPlus
	IniWrite, %WinX%, ScratchpadPlusData.ini, Settings, WindowPositionX
	IniWrite, %WinY%, ScratchpadPlusData.ini, Settings, WindowPositionY
	
return

ReadFromIni:
	IfExist, ScratchpadPlusData.ini
	{
		
		IniRead, newSaveOnExit, ScratchpadPlusData.ini, Settings, SaveOnExit
		IniRead, newStartMinimised, ScratchpadPlusData.ini, Settings, StartMinimised
		IniRead, newVisibilityHotkey, ScratchpadPlusData.ini, Settings, VisibilityHotkey
		IniRead, newUseWinkey, ScratchpadPlusData.ini, Settings, UseWinkey
		IniRead, LastActiveFile, ScratchpadPlusData.ini, Settings, LastActiveFile
		IniRead, WinX, ScratchpadPlusData.ini, Settings, WindowPositionX
		IniRead, WinY, ScratchpadPlusData.ini, Settings, WindowPositionY
		
		GuiControl,, SaveOnExit, %newSaveOnExit%
		GuiControl,, StartMinimised, %newStartMinimised%
		GuiControl,, VisibilityHotkey, %newVisibilityHotkey%
		GuiControl,, UseWinkey, %newUseWinkey%
		GuiControl,, History, %LastActiveFile%
		
		WinMove, WinX, WinY
	}
return

LoadOnStart:
	if LastActiveFile ; Not blank
	{
		if FileExist(LastActiveFile)
		{
			FileRead, filecontents, %LastActiveFile%
			sci.SetText(null,  filecontents)
			sci.GrabFocus()
			FileGetTime, RecordedLastModified, %LastActiveFile%, M
		}
		else
		{
			WinSet, AlwaysOnTop, Off
			MsgBox, 16, File not found — ScratchpadPlus, The last used file could not be found. Has it been moved or deleted?`n`nLoading template instead.`n`n(%LastActiveFile%)
			WinSet, AlwaysOnTop, On
			
			GoSub, LoadTemplate
		}

		GoSub, UpdateVars
	}
	else
	{
		GoSub, LoadTemplate
	}
return

Open:
	WinSet, AlwaysOnTop, Off
	FileSelectFile, openfilename,3,,Open a file? — Scratchpad, Documents (*.txt)
	
	if ErrorLevel
		return
	
	if openfilename != ""
	{
		FileRead, filecontents, %openfilename%
		sci.SetText(null,  filecontents)
		sci.GrabFocus()
		LastActiveFile := openfilename
		GuiControl,,History, %LastActiveFile%
		FileGetTime, RecordedLastModified, %LastActiveFile%, M
		
		GoSub, UpdateVars
	}
	
	WinSet, AlwaysOnTop, On
return

New:
	GoSub, Save
	GoSub, LoadTemplate
	GoSub, UpdateVars
return

UpdateVars:
		Gui, Submit, NoHide
		GoSub, WriteToIni
return

UpdateText:
	GoSub, UpdateVars
	WinSetTitle, %UnsavedWindowTitle%
return

WM_SYSCOMMAND(wParam)
{
  if (A_Gui && wParam = 0xF020) ; SC_MINIMIZE
  {
    Gui, Hide
    return 0
  }
}

GuiShowHide:
	If DllCall( "IsWindowVisible", "UInt",GUI1 )
	{
		Gui, Hide
	}
	else
	{
  		RefreshActiveFile(LastActiveFile)
  		Gui, Show
	}
Return

GuiHideOnly:
	Gui, Hide
return

LoadTemplate:
	filecontents = ""
	IfExist, template/template.txt
		FileRead, filecontents, template/template.txt
	sci.SetText(null,  filecontents)
	sci.GrabFocus()
	
	LastActiveFile =
	GuiControl,,History, Editing a new template
return

SaveAs:
	WinSet, AlwaysOnTop, Off
	
	if LastActiveFile ;is not blank
		filename := LastActiveFile
	else
		filename = %A_WorkingDir%\%A_DD% %A_MMM% %A_YYYY% %A_Hour%%A_Min%.txt
			
	FileSelectFile, savefilename, S24, %filename%,Save this file? — ScratchpadPlus, Documents (*.txt)
	
	if ErrorLevel = 0
	{
		if savefilename != ""
		{
			if RegExMatch(savefilename, "(.txt)$")
			{
				FileDelete, %savefilename%
				FileAppend, %Text%, %savefilename%
				LastActiveFile := savefilename
			}
			else
			{
				FileDelete, %savefilename%.txt
				sci.GetText(sci.GetLength()+1,MyVar)
				FileAppend, %MyVar%, %savefilename%.txt
				LastActiveFile := savefilename . ".txt"
			}
			
			GuiControl,,History, %LastActiveFile%
			GoSub, UpdateVars
			WinSetTitle, %DefaultWindowTitle%
			FileGetTime, RecordedLastModified, %LastActiveFile%, M
		}
	}
	
	WinSet, AlwaysOnTop, On
return

Save:
	WinSet, AlwaysOnTop, Off
	
	if LastActiveFile ;not blank
	{
		if FileExist(LastActiveFile)
		{
			if ConfirmSave(LastActiveFile) = 1
			{
				FileDelete, %LastActiveFile%
				sci.GetText(sci.GetLength()+1,MyVar)
				FileAppend, %MyVar%, %LastActiveFile%
				
				GuiControl,,History, %LastActiveFile%
				GoSub, UpdateVars
				WinSetTitle, %DefaultWindowTitle%
				
				FileGetTime, RecordedLastModified, %LastActiveFile%, M
			}
		}
		else
		{
			GoSub, SaveAs
		}
	}
	else
	{
		GoSub, SaveAs
	}
		
	WinSet, AlwaysOnTop, On
return

SaveOnExit:
	GoSub, UpdateVars
	
	WinSet, AlwaysOnTop, Off
	
	if SaveOnExit = 1
	{
		if LastActiveFile ;not blank
		{
			if FileExist(LastActiveFile)
			{
				if ConfirmSave(LastActiveFile) = 1
				{
					BackupFilename := LastActiveFile . ".bak"
					FileCopy, %LastActiveFile%, %BackupFilename%, 1
					
					FileDelete, %LastActiveFile%
					sci.GetText(sci.GetLength()+1,MyVar)
					FileAppend, %MyVar%, %LastActiveFile%
				}
			}
			else
			{
				GoSub, SaveAs
			}
		}
		else
		{
			GoSub, SaveAs
		}
	}
	
	ExitApp
return


; This function handles the Click notifications and tells Scintilla to Fold/Unfold
SCI_NOTIFY(wParam, lParam, msg, hwnd, sciObj) {

	line := sciObj.LineFromPosition(sciObj.position)

	if (sciObj.scnCode = SCN_MARGINCLICK)
		sciObj.ToggleFold(line)
}


CheckTimestamp(File)
{
	global RecordedLastModified
	FileGetTime, CurrentLastModified, %File%, M
	EnvSub, CurrentLastModified, %RecordedLastModified%, Seconds
	
	if CurrentLastModified > 0
	{
		return 1
	}
	else
	{
		return 0
	}
}

ConfirmSave(File)
{
	if CheckTimestamp(File) = 1
	{
		SplitPath, File, Filename
		MsgBox, 52, This file has been changed since you last opened it — ScratchpadPlus, Your active file, '%Filename%' was changed after it was opened in Scratchpad. Are you sure you want to save ScratchpadPlus' version?
		
		IfMsgBox Yes
		{
			return 1
		}
		else
		{
			return 0
		}
	}
	else
	{
		return 1
	}
}

RefreshActiveFile(File)
{
	if CheckTimestamp(File) = 1
	{
		GoSub, LoadOnStart
	}
}

Search(sci, tStart, tEnd, str, flags = ""){

    sci.SetSearchFlags(flags), sci.SetTargetStart(tStart), sci.SetTargetEnd(tEnd)
    return pos:=sci.SearchInTarget(strlen(str), str)
}