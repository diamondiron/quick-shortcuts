; ========================================
; Numpad Macro Pad - Context-Sensitive Boilerplate
; ========================================
; This script converts your numpad into a context-sensitive macro pad
; Different applications get different numpad functions
; ========================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ========================================
; INITIALIZATION
; ========================================

; Set NumLock to ON state at startup
SetNumLockState "AlwaysOn"

; Show tooltip notification that script is running
TrayTip "Numpad Macro Pad", "Script loaded successfully!`nNumLock is locked ON", 1

; ========================================
; NUMLOCK PROTECTION
; ========================================
; This prevents NumLock from being toggled off
; Comment out if you want to allow NumLock toggling

NumLock::Return  ; Blocks the NumLock key entirely

; Alternative: Auto-restore NumLock if it gets turned off somehow
; SetTimer CheckNumLock, 1000
; CheckNumLock() {
;     if !GetKeyState("NumLock", "T")
;         SetNumLockState "AlwaysOn"
; }

; ========================================
; GLOBAL NUMPAD FUNCTIONS (All Apps)
; ========================================
; These work everywhere unless overridden by app-specific hotkeys

; Example: NumpadEnter always sends Ctrl+Enter
; NumpadEnter::Send "^{Enter}"

; ========================================
; VISUAL STUDIO CODE
; ========================================
#HotIf WinActive("ahk_exe Code.exe")

    Numpad7::Send "^+p"              ; Command Palette
    Numpad8::Send "^p"                ; Quick Open File
    Numpad9::Send "^+f"               ; Find in Files
    
    Numpad4::Send "^/"                ; Toggle Comment
    Numpad5::Send "^d"                ; Select Next Occurrence
    Numpad6::Send "^+k"               ; Delete Line
    
    Numpad1::Send "^``"               ; Toggle Terminal
    Numpad2::Send "{F5}"              ; Start Debugging
    Numpad3::Send "+!f"               ; Format Document
    
    Numpad0::Send "^b"                ; Toggle Sidebar
    NumpadDot::Send "^+e"             ; Focus Explorer
    NumpadEnter::Send "!{Enter}"      ; Show Hover Info

#HotIf

; ========================================
; CHROME / EDGE
; ========================================
#HotIf WinActive("ahk_exe chrome.exe") or WinActive("ahk_exe msedge.exe")

    Numpad7::Send "^t"                ; New Tab
    Numpad8::Send "^w"                ; Close Tab
    Numpad9::Send "^+t"               ; Reopen Closed Tab
    
    Numpad4::Send "^{Tab}"            ; Next Tab
    Numpad5::Send "^+{Tab}"           ; Previous Tab
    Numpad6::Send "^l"                ; Focus Address Bar
    
    Numpad1::Send "^h"                ; History
    Numpad2::Send "^j"                ; Downloads
    Numpad3::Send "^+{Delete}"        ; Clear Browsing Data
    
    Numpad0::Send "{F5}"              ; Refresh
    NumpadDot::Send "^+i"             ; Developer Tools
    NumpadEnter::Send "^{Enter}"      ; Open Link in New Tab

#HotIf

; ========================================
; WINDOWS EXPLORER
; ========================================
#HotIf WinActive("ahk_class CabinetWClass")

    Numpad7::Send "^n"                ; New Window
    Numpad8::Send "!{Up}"             ; Up One Directory
    Numpad9::Send "^w"                ; Close Window
    
    Numpad4::Send "!{Left}"           ; Back
    Numpad5::Send "!{Right}"          ; Forward
    Numpad6::Send "{F5}"              ; Refresh
    
    Numpad1::Send "^+n"               ; New Folder
    Numpad2::Send "{F2}"              ; Rename
    Numpad3::Send "{Delete}"          ; Delete
    
    Numpad0::Send "^a"                ; Select All
    NumpadDot::Send "!{Enter}"        ; Properties
    NumpadEnter::Send "{Enter}"       ; Open/Execute

#HotIf

; ========================================
; EXCEL
; ========================================
#HotIf WinActive("ahk_exe EXCEL.EXE")

    Numpad7::Send "^{Home}"           ; Go to A1
    Numpad8::Send "^{Up}"             ; Jump to Top of Column
    Numpad9::Send "^{PgUp}"           ; Previous Sheet
    
    Numpad4::Send "^{Left}"           ; Jump to Start of Row
    Numpad5::Send "^;"                ; Insert Current Date
    Numpad6::Send "^{Right}"          ; Jump to End of Row
    
    Numpad1::Send "^{PgDn}"           ; Next Sheet
    Numpad2::Send "^{Down}"           ; Jump to Bottom of Column
    Numpad3::Send "^{End}"            ; Go to Last Used Cell
    
    Numpad0::Send "!="                ; AutoSum
    NumpadDot::Send "{F2}"            ; Edit Cell
    NumpadEnter::Send "^{Enter}"      ; Fill Down

#HotIf

; ========================================
; PHOTOSHOP
; ========================================
#HotIf WinActive("ahk_exe Photoshop.exe")

    Numpad7::Send "v"                 ; Move Tool
    Numpad8::Send "m"                 ; Marquee Tool
    Numpad9::Send "l"                 ; Lasso Tool
    
    Numpad4::Send "w"                 ; Magic Wand
    Numpad5::Send "c"                 ; Crop Tool
    Numpad6::Send "e"                 ; Eraser Tool
    
    Numpad1::Send "b"                 ; Brush Tool
    Numpad2::Send "s"                 ; Clone Stamp
    Numpad3::Send "g"                 ; Gradient Tool
    
    Numpad0::Send "{Space}"           ; Hand Tool (while held)
    NumpadDot::Send "t"               ; Text Tool
    NumpadEnter::Send "^;"            ; Show/Hide Guides

#HotIf

; ========================================
; DISCORD
; ========================================
#HotIf WinActive("ahk_exe Discord.exe")

    Numpad7::Send "^k"                ; Quick Switcher
    Numpad8::Send "!{Up}"             ; Previous Channel
    Numpad9::Send "!{Down}"           ; Next Channel
    
    Numpad4::Send "^+{Up}"            ; Previous Unread
    Numpad5::Send "^+"               ; Mark as Read
    Numpad6::Send "^+{Down}"          ; Next Unread
    
    Numpad1::Send "^+m"               ; Toggle Mute
    Numpad2::Send "^+d"               ; Toggle Deafen
    Numpad3::Send "!a"                ; Answer Call
    
    Numpad0::Send "^i"                ; Toggle Inbox
    NumpadDot::Send "^u"              ; Show Mentions
    NumpadEnter::Send "^{Enter}"      ; Send Message

#HotIf

; ========================================
; DEFAULT / FALLBACK (No specific app)
; ========================================
; These activate when no other context matches
; Uncomment and customize as needed

/*
#HotIf !WinActive("ahk_exe Code.exe") and !WinActive("ahk_exe chrome.exe")
    
    Numpad7::Send "{Home}"
    Numpad8::Send "{Up}"
    Numpad9::Send "{PgUp}"
    
    Numpad4::Send "{Left}"
    Numpad5::                         ; Do nothing (or custom action)
    Numpad6::Send "{Right}"
    
    Numpad1::Send "{End}"
    Numpad2::Send "{Down}"
    Numpad3::Send "{PgDn}"
    
    Numpad0::Send "{Insert}"
    NumpadDot::Send "{Delete}"
    NumpadEnter::Send "{Enter}"

#HotIf
*/

; ========================================
; UTILITY FUNCTIONS
; ========================================

; Get information about the active window (for debugging/adding new apps)
; Press Ctrl+Alt+W to see window information
^!w:: {
    WinTitle := WinGetTitle("A")
    WinClass := WinGetClass("A")
    WinExe := WinGetProcessName("A")
    
    Result := "
    (
    Window Title: " WinTitle "
    Window Class: " WinClass "
    Process Name: " WinExe "
    )"
    
    MsgBox Result, "Active Window Information"
}

; Reload script - Ctrl+Alt+R
^!r:: {
    Reload
}

; Exit script - Ctrl+Alt+Q
^!q:: {
    ExitApp
}

; ========================================
; INSTRUCTIONS FOR ADDING NEW APPS
; ========================================
/*
1. Use Ctrl+Alt+W while focused on your target application to get its info
2. Add a new #HotIf block with the appropriate ahk_exe or ahk_class
3. Define your numpad keys and their actions
4. Save and press Ctrl+Alt+R to reload the script

Example template:
#HotIf WinActive("ahk_exe YourApp.exe")
    Numpad7::Send "your_command_here"
    ; ... more mappings
#HotIf
*/
