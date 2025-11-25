; ========================================
; Numpad Macro Pad - Context-Sensitive Boilerplate
; ========================================
; Full GUI editor with persistent configuration
; ========================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ========================================
; GLOBAL VARIABLES
; ========================================
global ConfigFile := A_ScriptDir "\numpad_config.ini"
global AppMappings := Map()
global RegisteredHotkeys := []
global MainGui := ""
global CurrentApp := ""

; Numpad key display names
global NumpadKeys := Map(
    "Numpad7", "Num 7",
    "Numpad8", "Num 8",
    "Numpad9", "Num 9",
    "Numpad4", "Num 4",
    "Numpad5", "Num 5",
    "Numpad6", "Num 6",
    "Numpad1", "Num 1",
    "Numpad2", "Num 2",
    "Numpad3", "Num 3",
    "Numpad0", "Num 0",
    "NumpadDot", "Num .",
    "NumpadEnter", "Num Enter",
    "NumpadAdd", "Num +",
    "NumpadSub", "Num -",
    "NumpadMult", "Num *",
    "NumpadDiv", "Num /"
)

; ========================================
; INITIALIZATION
; ========================================
SetNumLockState "AlwaysOn"
NumLock::Return

; Generate and set tray icon
GenerateTrayIcon()

; Load config and register hotkeys
LoadConfig()
RegisterAllHotkeys()

; Setup tray menu
SetupTrayMenu()

TrayTip "Numpad Macro Pad", "Loaded " AppMappings.Count " app profiles", 1

; ========================================
; TRAY ICON GENERATION (Lightning Bolt)
; ========================================
GenerateTrayIcon() {
    static iconPath := A_Temp "\numpad_macro_icon.ico"
    
    ; Create a 32x32 icon using GDI+
    pToken := Gdip_Startup()
    
    pBitmap := Gdip_CreateBitmap(32, 32)
    G := Gdip_GraphicsFromImage(pBitmap)
    Gdip_SetSmoothingMode(G, 4)
    
    ; Background - dark blue circle
    pBrushBg := Gdip_BrushCreateSolid(0xFF1a1a2e)
    Gdip_FillEllipse(G, pBrushBg, 1, 1, 30, 30)
    Gdip_DeleteBrush(pBrushBg)
    
    ; Lightning bolt - yellow/gold
    pBrushBolt := Gdip_BrushCreateSolid(0xFFffd700)
    
    ; Lightning bolt points (simplified polygon)
    Points := "18,4|10,14|14,14|8,28|22,16|17,16|22,4"
    Gdip_FillPolygon(G, pBrushBolt, Points)
    Gdip_DeleteBrush(pBrushBolt)
    
    ; Add slight glow effect
    pBrushGlow := Gdip_BrushCreateSolid(0x40ffff00)
    Gdip_FillEllipse(G, pBrushGlow, 6, 6, 20, 20)
    Gdip_DeleteBrush(pBrushGlow)
    
    ; Save as ICO
    Gdip_SaveBitmapToFile(pBitmap, iconPath)
    
    ; Cleanup GDI+
    Gdip_DeleteGraphics(G)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
    
    ; Set tray icon
    if FileExist(iconPath)
        TraySetIcon(iconPath)
}

; ========================================
; GDI+ FUNCTIONS
; ========================================
Gdip_Startup() {
    DllCall("LoadLibrary", "str", "gdiplus")
    si := Buffer(24, 0)
    NumPut("uint", 1, si)
    pToken := 0
    DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken, "ptr", si, "ptr", 0)
    return pToken
}

Gdip_Shutdown(pToken) {
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
}

Gdip_CreateBitmap(w, h) {
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", 0, "int", 0x26200A, "ptr", 0, "ptr*", &pBitmap)
    return pBitmap
}

Gdip_GraphicsFromImage(pBitmap) {
    pGraphics := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &pGraphics)
    return pGraphics
}

Gdip_DeleteGraphics(pGraphics) {
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
}

Gdip_DisposeImage(pBitmap) {
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
}

Gdip_SetSmoothingMode(pGraphics, mode) {
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", pGraphics, "int", mode)
}

Gdip_BrushCreateSolid(ARGB) {
    pBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", ARGB, "ptr*", &pBrush)
    return pBrush
}

Gdip_DeleteBrush(pBrush) {
    DllCall("gdiplus\GdipDeleteBrush", "ptr", pBrush)
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h) {
    DllCall("gdiplus\GdipFillEllipse", "ptr", pGraphics, "ptr", pBrush, "float", x, "float", y, "float", w, "float", h)
}

Gdip_FillPolygon(pGraphics, pBrush, Points) {
    PointsArr := StrSplit(Points, "|")
    PointCount := PointsArr.Length
    PointsBuffer := Buffer(8 * PointCount, 0)
    
    for i, pt in PointsArr {
        coords := StrSplit(pt, ",")
        NumPut("float", coords[1], "float", coords[2], PointsBuffer, (i-1) * 8)
    }
    
    DllCall("gdiplus\GdipFillPolygon", "ptr", pGraphics, "ptr", pBrush, "ptr", PointsBuffer, "int", PointCount, "int", 0)
}

Gdip_SaveBitmapToFile(pBitmap, sOutput) {
    ; Get PNG encoder CLSID
    nCount := 0
    nSize := 0
    DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &nCount, "uint*", &nSize)
    ci := Buffer(nSize)
    DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "ptr", ci)
    
    ; Find PNG encoder
    pCodec := 0
    Loop nCount {
        offset := (A_Index - 1) * 76 + 44
        if InStr(StrGet(NumGet(ci, offset, "ptr"), "UTF-16"), "png") {
            pCodec := ci.Ptr + (A_Index - 1) * 76
            break
        }
    }
    
    if pCodec
        DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", sOutput, "ptr", pCodec, "ptr", 0)
}

; ========================================
; CONFIG MANAGEMENT
; ========================================
LoadConfig() {
    global AppMappings
    AppMappings := Map()
    
    if !FileExist(ConfigFile) {
        CreateDefaultConfig()
    }
    
    currentSection := ""
    
    Loop Read ConfigFile {
        line := Trim(A_LoopReadLine)
        
        if line = "" || SubStr(line, 1, 1) = ";"
            continue
        
        ; Section header [AppName|exe_identifier]
        if SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]" {
            currentSection := SubStr(line, 2, -1)
            if !AppMappings.Has(currentSection)
                AppMappings[currentSection] := Map()
            continue
        }
        
        ; Key=Value pair
        if currentSection && InStr(line, "=") {
            parts := StrSplit(line, "=",, 2)
            if parts.Length = 2 {
                key := Trim(parts[1])
                value := Trim(parts[2])
                AppMappings[currentSection][key] := value
            }
        }
    }
}

SaveConfig() {
    global AppMappings
    
    content := "; Numpad Macro Pad Configuration`n"
    content .= "; Format: [AppName|ahk_identifier]`n"
    content .= "; NumpadKey=SendCommand|Description`n`n"
    
    for appId, mappings in AppMappings {
        content .= "[" appId "]`n"
        for key, value in mappings {
            content .= key "=" value "`n"
        }
        content .= "`n"
    }
    
    try {
        FileDelete ConfigFile
    }
    FileAppend content, ConfigFile
}

CreateDefaultConfig() {
    defaultConfig := "
    (
; Numpad Macro Pad Configuration
; Format: [AppName|ahk_identifier]
; NumpadKey=SendCommand|Description

[VS Code|ahk_exe Code.exe]
Numpad7=^+p|Command Palette
Numpad8=^p|Quick Open File
Numpad9=^+f|Find in Files
Numpad4=^/|Toggle Comment
Numpad5=^d|Select Next Occurrence
Numpad6=^+k|Delete Line
Numpad1=^``|Toggle Terminal
Numpad2={F5}|Start Debugging
Numpad3=+!f|Format Document
Numpad0=^b|Toggle Sidebar
NumpadDot=^+e|Focus Explorer
NumpadEnter=!{Enter}|Show Hover Info

[Chrome|ahk_exe chrome.exe]
Numpad7=^t|New Tab
Numpad8=^w|Close Tab
Numpad9=^+t|Reopen Closed Tab
Numpad4=^{Tab}|Next Tab
Numpad5=^+{Tab}|Previous Tab
Numpad6=^l|Focus Address Bar
Numpad1=^h|History
Numpad2=^j|Downloads
Numpad3=^+{Delete}|Clear Browsing Data
Numpad0={F5}|Refresh
NumpadDot=^+i|Developer Tools
NumpadEnter=^{Enter}|Open in New Tab

[Edge|ahk_exe msedge.exe]
Numpad7=^t|New Tab
Numpad8=^w|Close Tab
Numpad9=^+t|Reopen Closed Tab
Numpad4=^{Tab}|Next Tab
Numpad5=^+{Tab}|Previous Tab
Numpad6=^l|Focus Address Bar
Numpad1=^h|History
Numpad2=^j|Downloads
Numpad3=^+{Delete}|Clear Browsing Data
Numpad0={F5}|Refresh
NumpadDot=^+i|Developer Tools
NumpadEnter=^{Enter}|Open in New Tab

[Explorer|ahk_class CabinetWClass]
Numpad7=^n|New Window
Numpad8=!{Up}|Up One Directory
Numpad9=^w|Close Window
Numpad4=!{Left}|Back
Numpad5=!{Right}|Forward
Numpad6={F5}|Refresh
Numpad1=^+n|New Folder
Numpad2={F2}|Rename
Numpad3={Delete}|Delete
Numpad0=^a|Select All
NumpadDot=!{Enter}|Properties
NumpadEnter={Enter}|Open/Execute

[Excel|ahk_exe EXCEL.EXE]
Numpad7=^{Home}|Go to A1
Numpad8=^{Up}|Jump to Top of Column
Numpad9=^{PgUp}|Previous Sheet
Numpad4=^{Left}|Jump to Start of Row
Numpad5=^;|Insert Current Date
Numpad6=^{Right}|Jump to End of Row
Numpad1=^{PgDn}|Next Sheet
Numpad2=^{Down}|Jump to Bottom of Column
Numpad3=^{End}|Go to Last Used Cell
Numpad0=!=|AutoSum
NumpadDot={F2}|Edit Cell
NumpadEnter=^{Enter}|Fill Down

[Discord|ahk_exe Discord.exe]
Numpad7=^k|Quick Switcher
Numpad8=!{Up}|Previous Channel
Numpad9=!{Down}|Next Channel
Numpad4=^+{Up}|Previous Unread
Numpad5=^+|Mark as Read
Numpad6=^+{Down}|Next Unread
Numpad1=^+m|Toggle Mute
Numpad2=^+d|Toggle Deafen
Numpad3=!a|Answer Call
Numpad0=^i|Toggle Inbox
NumpadDot=^u|Show Mentions
NumpadEnter=^{Enter}|Send Message
)"
    
    FileAppend defaultConfig, ConfigFile
}

; ========================================
; DYNAMIC HOTKEY REGISTRATION
; ========================================
RegisterAllHotkeys() {
    global AppMappings, RegisteredHotkeys
    
    ; Unregister existing hotkeys
    for hk in RegisteredHotkeys {
        try Hotkey hk, "Off"
    }
    RegisteredHotkeys := []
    
    ; Register hotkeys for each app
    for appId, mappings in AppMappings {
        ; Parse app identifier
        parts := StrSplit(appId, "|")
        if parts.Length < 2
            continue
            
        appName := parts[1]
        ahkId := parts[2]
        
        for numKey, actionData in mappings {
            actionParts := StrSplit(actionData, "|",, 2)
            sendCmd := actionParts[1]
            
            ; Create hotkey with context
            try {
                HotIfWinActive(ahkId)
                Hotkey numKey, CreateSendFunc(sendCmd), "On"
                RegisteredHotkeys.Push(numKey)
            }
        }
    }
    
    ; Reset context
    HotIfWinActive()
}

CreateSendFunc(cmd) {
    return (*) => Send(cmd)
}

; ========================================
; TRAY MENU
; ========================================
SetupTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("&Open Editor", (*) => ShowMainGui())
    A_TrayMenu.Add("&Quick Reference", (*) => ShowQuickRef())
    A_TrayMenu.Add()
    A_TrayMenu.Add("&Reload Config", (*) => ReloadConfig())
    A_TrayMenu.Add()
    A_TrayMenu.Add("E&xit", (*) => ExitApp())
    A_TrayMenu.Default := "&Open Editor"
}

ReloadConfig() {
    LoadConfig()
    RegisterAllHotkeys()
    TrayTip "Numpad Macro Pad", "Configuration reloaded!`n" AppMappings.Count " app profiles loaded", 1
}

; ========================================
; MAIN GUI - FULL EDITOR
; ========================================
ShowMainGui() {
    global MainGui, AppMappings, CurrentApp
    
    if MainGui {
        MainGui.Show()
        return
    }
    
    MainGui := Gui("+Resize", "Numpad Macro Pad Editor")
    MainGui.SetFont("s10", "Segoe UI")
    MainGui.BackColor := "1a1a2e"
    
    ; App list panel (left)
    MainGui.SetFont("s10 cWhite")
    MainGui.AddText("x10 y10 w180", "Applications:")
    
    MainGui.AddListBox("vAppList x10 y35 w180 h350 Background2d2d44 cWhite", GetAppNames())
    MainGui.OnEvent("Close", (*) => MainGui.Hide())
    
    ; Buttons for app management
    MainGui.AddButton("vAddAppBtn x10 y395 w85 h30", "Add App").OnEvent("Click", (*) => AddAppDialog())
    MainGui.AddButton("vDelAppBtn x100 y395 w90 h30", "Remove App").OnEvent("Click", (*) => RemoveApp())
    
    ; Mappings panel (right)
    MainGui.AddText("x210 y10 w400", "Key Mappings:")
    
    ; ListView for mappings
    MainGui.AddListView("vMappingList x210 y35 w450 h310 Background2d2d44 cWhite Grid", ["Key", "Command", "Description"])
    MainGui["MappingList"].ModifyCol(1, 80)
    MainGui["MappingList"].ModifyCol(2, 180)
    MainGui["MappingList"].ModifyCol(3, 170)
    
    ; Mapping buttons
    MainGui.AddButton("vAddMapBtn x210 y355 w100 h30", "Add Mapping").OnEvent("Click", (*) => AddMappingDialog())
    MainGui.AddButton("vEditMapBtn x320 y355 w100 h30", "Edit").OnEvent("Click", (*) => EditMappingDialog())
    MainGui.AddButton("vDelMapBtn x430 y355 w100 h30", "Remove").OnEvent("Click", (*) => RemoveMapping())
    
    ; Save/Cancel buttons
    MainGui.AddButton("vSaveBtn x430 y395 w110 h30", "Save Config").OnEvent("Click", (*) => SaveAndReload())
    MainGui.AddButton("vDetectBtn x540 y355 w120 h30", "Detect Window").OnEvent("Click", (*) => DetectWindow())
    
    ; Status bar
    MainGui.AddText("vStatus x210 y430 w450 cGray", "Select an application to view mappings")
    
    ; App selection event
    MainGui["AppList"].OnEvent("Change", (*) => LoadAppMappings())
    
    MainGui.Show("w680 h460")
}

GetAppNames() {
    names := []
    for appId, _ in AppMappings {
        parts := StrSplit(appId, "|")
        names.Push(parts[1])
    }
    return names
}

GetAppIdByName(name) {
    for appId, _ in AppMappings {
        if InStr(appId, name "|")
            return appId
    }
    return ""
}

LoadAppMappings() {
    global MainGui, AppMappings, CurrentApp
    
    selected := MainGui["AppList"].Text
    if !selected
        return
    
    CurrentApp := GetAppIdByName(selected)
    if !CurrentApp
        return
    
    lv := MainGui["MappingList"]
    lv.Delete()
    
    if AppMappings.Has(CurrentApp) {
        for numKey, actionData in AppMappings[CurrentApp] {
            parts := StrSplit(actionData, "|",, 2)
            cmd := parts[1]
            desc := parts.Length > 1 ? parts[2] : ""
            displayKey := NumpadKeys.Has(numKey) ? NumpadKeys[numKey] : numKey
            lv.Add(, displayKey, cmd, desc)
        }
    }
    
    parts := StrSplit(CurrentApp, "|")
    MainGui["Status"].Value := "Editing: " parts[1] " (" parts[2] ")"
}

; ========================================
; DIALOG FUNCTIONS
; ========================================
AddAppDialog() {
    global AppMappings, MainGui
    
    dg := Gui("+Owner" MainGui.Hwnd " +ToolWindow", "Add Application")
    dg.SetFont("s10", "Segoe UI")
    dg.BackColor := "1a1a2e"
    dg.SetFont("cWhite")
    
    dg.AddText("x10 y10 w280", "Application Name (display):")
    dg.AddEdit("vAppName x10 y30 w280 Background2d2d44 cWhite")
    
    dg.AddText("x10 y60 w280", "Window Identifier (ahk_exe or ahk_class):")
    dg.AddEdit("vAhkId x10 y80 w280 Background2d2d44 cWhite", "ahk_exe ")
    
    dg.AddText("x10 y110 w280 cGray", "Tip: Use 'Detect Window' in main editor")
    
    dg.AddButton("x80 y140 w100 h30", "Add").OnEvent("Click", AddAppSubmit)
    dg.AddButton("x190 y140 w100 h30", "Cancel").OnEvent("Click", (*) => dg.Destroy())
    
    AddAppSubmit(*) {
        appName := dg["AppName"].Value
        ahkId := dg["AhkId"].Value
        
        if !appName || !ahkId {
            MsgBox "Please fill in both fields", "Error"
            return
        }
        
        newAppId := appName "|" ahkId
        if AppMappings.Has(newAppId) {
            MsgBox "Application already exists", "Error"
            return
        }
        
        AppMappings[newAppId] := Map()
        RefreshAppList()
        dg.Destroy()
    }
    
    dg.Show()
}

RemoveApp() {
    global MainGui, AppMappings, CurrentApp
    
    if !CurrentApp {
        MsgBox "Select an application first", "Error"
        return
    }
    
    parts := StrSplit(CurrentApp, "|")
    if MsgBox("Remove '" parts[1] "' and all its mappings?",, "YesNo") = "Yes" {
        AppMappings.Delete(CurrentApp)
        CurrentApp := ""
        RefreshAppList()
        MainGui["MappingList"].Delete()
        MainGui["Status"].Value := "Application removed"
    }
}

AddMappingDialog() {
    global MainGui, AppMappings, CurrentApp, NumpadKeys
    
    if !CurrentApp {
        MsgBox "Select an application first", "Error"
        return
    }
    
    dg := Gui("+Owner" MainGui.Hwnd " +ToolWindow", "Add Mapping")
    dg.SetFont("s10", "Segoe UI")
    dg.BackColor := "1a1a2e"
    dg.SetFont("cWhite")
    
    dg.AddText("x10 y10 w180", "Numpad Key:")
    keyList := []
    for k, v in NumpadKeys
        keyList.Push(v)
    dg.AddDropDownList("vKeySelect x10 y30 w180 Background2d2d44", keyList)
    
    dg.AddText("x10 y60 w280", "Send Command (e.g., ^c, {F5}, !{Enter}):")
    dg.AddEdit("vSendCmd x10 y80 w280 Background2d2d44 cWhite")
    
    dg.AddText("x10 y110 w280", "Description:")
    dg.AddEdit("vDesc x10 y130 w280 Background2d2d44 cWhite")
    
    dg.AddButton("x80 y170 w100 h30", "Add").OnEvent("Click", AddMapSubmit)
    dg.AddButton("x190 y170 w100 h30", "Cancel").OnEvent("Click", (*) => dg.Destroy())
    
    AddMapSubmit(*) {
        keyDisplay := dg["KeySelect"].Text
        sendCmd := dg["SendCmd"].Value
        desc := dg["Desc"].Value
        
        if !keyDisplay || !sendCmd {
            MsgBox "Please select a key and enter a command", "Error"
            return
        }
        
        ; Convert display name back to key name
        keyName := ""
        for k, v in NumpadKeys {
            if v = keyDisplay {
                keyName := k
                break
            }
        }
        
        if !keyName {
            MsgBox "Invalid key selection", "Error"
            return
        }
        
        AppMappings[CurrentApp][keyName] := sendCmd "|" desc
        LoadAppMappings()
        dg.Destroy()
    }
    
    dg.Show()
}

EditMappingDialog() {
    global MainGui, AppMappings, CurrentApp, NumpadKeys
    
    if !CurrentApp {
        MsgBox "Select an application first", "Error"
        return
    }
    
    row := MainGui["MappingList"].GetNext()
    if !row {
        MsgBox "Select a mapping to edit", "Error"
        return
    }
    
    keyDisplay := MainGui["MappingList"].GetText(row, 1)
    oldCmd := MainGui["MappingList"].GetText(row, 2)
    oldDesc := MainGui["MappingList"].GetText(row, 3)
    
    ; Find original key name
    keyName := ""
    for k, v in NumpadKeys {
        if v = keyDisplay {
            keyName := k
            break
        }
    }
    
    dg := Gui("+Owner" MainGui.Hwnd " +ToolWindow", "Edit Mapping")
    dg.SetFont("s10", "Segoe UI")
    dg.BackColor := "1a1a2e"
    dg.SetFont("cWhite")
    
    dg.AddText("x10 y10 w180", "Key: " keyDisplay)
    
    dg.AddText("x10 y40 w280", "Send Command:")
    dg.AddEdit("vSendCmd x10 y60 w280 Background2d2d44 cWhite", oldCmd)
    
    dg.AddText("x10 y90 w280", "Description:")
    dg.AddEdit("vDesc x10 y110 w280 Background2d2d44 cWhite", oldDesc)
    
    dg.AddButton("x80 y150 w100 h30", "Save").OnEvent("Click", EditMapSubmit)
    dg.AddButton("x190 y150 w100 h30", "Cancel").OnEvent("Click", (*) => dg.Destroy())
    
    EditMapSubmit(*) {
        sendCmd := dg["SendCmd"].Value
        desc := dg["Desc"].Value
        
        if !sendCmd {
            MsgBox "Please enter a command", "Error"
            return
        }
        
        AppMappings[CurrentApp][keyName] := sendCmd "|" desc
        LoadAppMappings()
        dg.Destroy()
    }
    
    dg.Show()
}

RemoveMapping() {
    global MainGui, AppMappings, CurrentApp, NumpadKeys
    
    if !CurrentApp {
        MsgBox "Select an application first", "Error"
        return
    }
    
    row := MainGui["MappingList"].GetNext()
    if !row {
        MsgBox "Select a mapping to remove", "Error"
        return
    }
    
    keyDisplay := MainGui["MappingList"].GetText(row, 1)
    
    ; Find original key name
    for k, v in NumpadKeys {
        if v = keyDisplay {
            AppMappings[CurrentApp].Delete(k)
            break
        }
    }
    
    LoadAppMappings()
}

DetectWindow() {
    global MainGui
    
    MainGui.Hide()
    
    MsgBox "Click OK, then within 3 seconds, click on the window you want to detect.",, "Detect Window"
    Sleep 3000
    
    WinTitle := WinGetTitle("A")
    WinClass := WinGetClass("A")
    WinExe := WinGetProcessName("A")
    
    result := "Window Title: " WinTitle "`n"
    result .= "Window Class: " WinClass "`n"
    result .= "Process Name: " WinExe "`n`n"
    result .= "Suggested identifiers:`n"
    result .= "ahk_exe " WinExe "`n"
    result .= "ahk_class " WinClass
    
    MsgBox result, "Window Information"
    
    MainGui.Show()
}

RefreshAppList() {
    global MainGui, AppMappings
    
    MainGui["AppList"].Delete()
    for name in GetAppNames()
        MainGui["AppList"].Add([name])
}

SaveAndReload() {
    SaveConfig()
    RegisterAllHotkeys()
    TrayTip "Numpad Macro Pad", "Configuration saved and hotkeys reloaded!", 1
    MainGui["Status"].Value := "Configuration saved successfully"
}

; ========================================
; QUICK REFERENCE POPUP
; ========================================
ShowQuickRef() {
    global AppMappings, NumpadKeys
    
    ; Get active window info
    try {
        activeExe := WinGetProcessName("A")
        activeClass := WinGetClass("A")
    } catch {
        activeExe := ""
        activeClass := ""
    }
    
    ; Find matching app
    matchedApp := ""
    matchedMappings := ""
    
    for appId, mappings in AppMappings {
        parts := StrSplit(appId, "|")
        ahkId := parts[2]
        
        if InStr(ahkId, activeExe) || InStr(ahkId, activeClass) {
            matchedApp := parts[1]
            matchedMappings := mappings
            break
        }
    }
    
    qr := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "Quick Reference")
    qr.BackColor := "1a1a2e"
    qr.SetFont("s11", "Consolas")
    qr.SetFont("cWhite")
    
    if matchedApp {
        qr.AddText("x10 y5 w300 cffd700 Center", matchedApp)
        y := 30
        
        for numKey, actionData in matchedMappings {
            parts := StrSplit(actionData, "|",, 2)
            desc := parts.Length > 1 ? parts[2] : parts[1]
            displayKey := NumpadKeys.Has(numKey) ? NumpadKeys[numKey] : numKey
            
            qr.SetFont("cffd700")
            qr.AddText("x10 y" y " w70", displayKey)
            qr.SetFont("cWhite")
            qr.AddText("x85 y" y " w215", desc)
            y += 22
        }
    } else {
        qr.AddText("x10 y10 w300 Center", "No mappings for current window")
        y := 50
    }
    
    qr.AddText("x10 y" (y + 10) " w300 cGray Center", "Click anywhere to close")
    
    qr.OnEvent("Click", (*) => qr.Destroy())
    qr.Show("AutoSize")
    
    ; Auto-close after 10 seconds
    SetTimer () => (qr ? qr.Destroy() : ""), -10000
}

; ========================================
; UTILITY HOTKEYS
; ========================================
^!w:: {
    WinTitle := WinGetTitle("A")
    WinClass := WinGetClass("A")
    WinExe := WinGetProcessName("A")
    
    Result := "Window Title: " WinTitle "`nWindow Class: " WinClass "`nProcess Name: " WinExe
    MsgBox Result, "Active Window Information"
}

^!r::Reload
^!q::ExitApp
^!m::ShowMainGui()  ; Open editor
^!`::ShowQuickRef()  ; Quick reference
