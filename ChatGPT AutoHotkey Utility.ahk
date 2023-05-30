#SingleInstance
#Include "_jxon.ahk"
Persistent

/*
====================================================
Script Tray Menu
====================================================
*/

TraySetIcon("Icon.ico")
A_TrayMenu.Delete
A_TrayMenu.Add("&Debug", Debug)
A_TrayMenu.Add("&Reload Script", ReloadScript)
A_TrayMenu.Add("E&xit", Exit)
A_IconTip := "ChatGPT AutoHotkey Utility"

ReloadScript(*) {
	Reload
}

Debug(*) {
	ListLines
}

Exit(*) {
	ExitApp
}

/*
====================================================
Dark mode menu
====================================================
*/

Class DarkMode {
    Static __New(Mode := 1) => ( ; Mode: Dark = 1, Default (Light) = 0
        DllCall(DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "uxtheme", "ptr"), "ptr", 135, "ptr"), "int", mode),
        DllCall(DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "uxtheme", "ptr"), "ptr", 136, "ptr"))
    )
}

/*
====================================================
Variables
====================================================
*/

API_Key := "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"
API_URL := "https://api.openai.com/v1/chat/completions"
API_Model := "gpt-3.5-turbo"
Status_Message := ""
Response_Window_Status := "Closed"
Retry_Status := ""

/*
====================================================
Menus and ChatGPT prompts
====================================================
*/

MenuPopup := Menu()
MenuPopup.Add("&1 - Rephrase", Rephrase)
MenuPopup.Add("&2 - Summarize", Summarize)
MenuPopup.Add("&3 - Explain", Explain)
MenuPopup.Add("&4 - Expand", Expand)
MenuPopup.Add()
MenuPopup.Add("&5 - Generate reply", GenerateReply)
MenuPopup.Add("&6 - Find action items", FindActionItems)
MenuPopup.Add("&7 - Translate to English", TranslateToEnglish)

Rephrase(*) {
    ChatGPT_Prompt := "Rephrase and rewrite the following so that it will be clear, concise, and flow naturally: `n`n"
    Status_Message := "Rephrasing..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

Summarize(*) {
    ChatGPT_Prompt := "Summarize the following: `n`n"
    Status_Message := "Summarizing..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

Explain(*) {
    ChatGPT_Prompt := "Explain the following: `n`n"
    Status_Message := "Explaining..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

Expand(*) {
    ChatGPT_Prompt := "Expand and enhance the following, so that it will be meaningful: `n`n"
    Status_Message := "Expanding..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

GenerateReply(*) {
    ChatGPT_Prompt := "Generate a reply to the following: `n`n"
    Status_Message := "Generating reply..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

FindActionItems(*) {
    ChatGPT_Prompt := "Find action items that needs to be done and present them in a list: `n`n"
    Status_Message := "Finding action items..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

TranslateToEnglish(*) {
    ChatGPT_Prompt := "Translate the following to English. Rephrase if necessary: `n`n"
    Status_Message := "Translating to English..."
    ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status)
}

/*
====================================================
Create Response Window
====================================================
*/

Response_Window := Gui("-Caption", "Response")
Response_Window.BackColor := "0x333333"
Response_Window.SetFont("s13 cWhite", "Georgia")
Response := Response_Window.Add("Edit", "r20 ReadOnly w600 Wrap Background333333", Status_Message)
RetryButton := Response_Window.Add("Button", "x190 Disabled", "Retry")
RetryButton.OnEvent("Click", Retry)
CopyButton := Response_Window.Add("Button", "x+30 w80 Disabled", "Copy")
CopyButton.OnEvent("Click", Copy)
Response_Window.Add("Button", "x+30", "Close").OnEvent("Click", Close)

/*
====================================================
Buttons
====================================================
*/

Retry(*) {
    Retry_Status := "Retry"
    RetryButton.Enabled := 0
    CopyButton.Enabled := 0
    CopyButton.Text := "Copy"
    ProcessRequest(Previous_ChatGPT_Prompt, Previous_Status_Message, Retry_Status)
}

Copy(*) {
    A_Clipboard := Response.Value
    CopyButton.Enabled := 0
    CopyButton.Text := "Copied!"

    DllCall("SetFocus", "Ptr", 0)
    Sleep 2000

    CopyButton.Enabled := 1
    CopyButton.Text := "Copy"
}

Close(*) {
    HTTP_Request.Abort
    Response_Window.Hide
    global Response_Window_Status := "Closed"
    Exit
}

/*
====================================================
Connect to ChatGPT API and process request
====================================================
*/

ProcessRequest(ChatGPT_Prompt, Status_Message, Retry_Status) {
    if (Retry_Status != "Retry") {
        A_Clipboard := ""
        Send "^c"
        ClipWait
        CopiedText := A_Clipboard
        ChatGPT_Prompt := ChatGPT_Prompt CopiedText
        ChatGPT_Prompt := RegExReplace(ChatGPT_Prompt, '(\\|")+', '\$1') ; Clean back spaces and quotes
        ChatGPT_Prompt := RegExReplace(ChatGPT_Prompt, "`n", "\n") ; Clean newlines
        ChatGPT_Prompt := RegExReplace(ChatGPT_Prompt, "`r", "") ; Remove carriage returns
        global Previous_ChatGPT_Prompt := ChatGPT_Prompt
        global Previous_Status_Message := Status_Message
        global Response_Window_Status
    }

    OnMessage 0x200, WM_MOUSEHOVER
    Response.Value := Status_Message
    if (Response_Window_Status = "Closed") {
        Response_Window.Show("AutoSize Center")
        Response_Window_Status := "Open"
        RetryButton.Enabled := 0
        CopyButton.Enabled := 0
    }    
    DllCall("SetFocus", "Ptr", 0)

    global HTTP_Request := ComObject("WinHttp.WinHttpRequest.5.1")
    HTTP_Request.open("POST", API_URL, true)
    HTTP_Request.SetRequestHeader("Content-Type", "application/json")
    HTTP_Request.SetRequestHeader("Authorization", "Bearer " API_Key)
    Messages := '{ "role": "user", "content": "' ChatGPT_Prompt '" }'
    JSON_Request := '{ "model": "' API_Model '", "messages": [' Messages '] }'
    HTTP_Request.SetTimeouts(60000, 60000, 60000, 60000)
    HTTP_Request.Send(JSON_Request)
    SetTimer LoadingCursor, 1
    if WinExist("Response") {
        WinActivate "Response"
    }
    HTTP_Request.WaitForResponse
    try {
        if (HTTP_Request.status == 200) {
            JSON_Response := HTTP_Request.responseText
            var := Jxon_Load(&JSON_Response)
            JSON_Response := var.Get("choices")[1].Get("message").Get("content")
            RetryButton.Enabled := 1
            CopyButton.Enabled := 1
            Response.Value := JSON_Response

            SetTimer LoadingCursor, 0
            OnMessage 0x200, WM_MOUSEHOVER, 0
            Cursor := DllCall("LoadCursor", "uint", 0, "uint", 32512) ; Arrow cursor
            DllCall("SetCursor", "UPtr", Cursor)

            Response_Window.Flash()
            DllCall("SetFocus", "Ptr", 0)
        } else {
            RetryButton.Enabled := 1
            CopyButton.Enabled := 1
            Response.Value := "Status " HTTP_Request.status " " HTTP_Request.responseText

            SetTimer LoadingCursor, 0
            OnMessage 0x200, WM_MOUSEHOVER, 0
            Cursor := DllCall("LoadCursor", "uint", 0, "uint", 32512) ; Arrow cursor
            DllCall("SetCursor", "UPtr", Cursor)

            Response_Window.Flash()
            DllCall("SetFocus", "Ptr", 0)
        }
    }
}

/*
====================================================
Cursors
====================================================
*/

WM_MOUSEHOVER(*) {
    Cursor := DllCall("LoadCursor", "uint", 0, "uint", 32648) ; Unavailable cursor
    MouseGetPos ,,, &MousePosition
    if (CopyButton.Enabled = 0) & (MousePosition = "Button2") {
        DllCall("SetCursor", "UPtr", Cursor)
    } else if (RetryButton.Enabled = 0) & (MousePosition = "Button1") | (MousePosition = "Button2") {
        DllCall("SetCursor", "UPtr", Cursor)
    }
}

LoadingCursor() {
    MouseGetPos ,,, &MousePosition
    if (MousePosition = "Edit1") {
        Cursor := DllCall("LoadCursor", "uint", 0, "uint", 32514) ; Loading cursor
        DllCall("SetCursor", "UPtr", Cursor)
    }
}

/*
====================================================
Hotkeys
====================================================
*/

`::MenuPopup.Show()