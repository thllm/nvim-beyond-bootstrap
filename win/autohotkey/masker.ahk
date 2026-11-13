#Requires AutoHotkey v2.0

; Ctrl + Alt + M
^!m::
{
    ; 1. Clear clipboard and send copy command
    A_Clipboard := ""
    Send("^c")
    
    ; 2. Wait up to 1 second for text to hit the clipboard
    if !ClipWait(1)
    {
        TrayTip("Masker", "No text selected!", "Iconx")
        SetTimer () => TrayTip(), -2000
        return
    }

    ; 3. Run the masking pipeline
    RunWait('powershell.exe -NoProfile -WindowStyle Hidden -Command "Get-Clipboard -Raw | wsl bash -c `'$HOME/.masker_stream.sh`' | Set-Clipboard"',, "Hide")
    
    ; 4. Notify success
    TrayTip("Masker", "Text copied and masked!", "Mute")
    SetTimer () => TrayTip(), -1000
}

; Ctrl + Alt + N (Opens clipboard directly in a new Neovim window)
^!n::
{
    ; Change the path after -d to wherever you want your files saved by default
    Run('wt.exe -d "C:\Users\tobia\nvimmers" powershell.exe -NoProfile -Command "Get-Clipboard -Raw | nvim -"')
}

; Ctrl + Alt + S (Copy selected text, or open a blank temp file if nothing is selected)
^!s::
{
    ; 1. Clear clipboard and send copy command
    A_Clipboard := ""
    Send("^c")
    
    ; 2. Wait up to 0.5 seconds for text to hit the clipboard
    if !ClipWait(0.5)
    {
        ; NO TEXT SELECTED: Just set a timestamped filename and open Neovim
        psCmd := "$f = (Get-Date -Format 'yyyyMMddHHmmss') + '-tmp-vim.txt'\; nvim $f"
    }
    else
    {
        ; TEXT SELECTED: Generate filename from words, save clipboard to it, then open
        psCmd := "$c = Get-Clipboard -Raw\; $w = ($c.Trim() -split '\s+')[0..1] -join '_'\; $w = $w -replace '[^a-zA-Z0-9_]',''\; $f = (Get-Date -Format 'yyyyMMddHHmmss') + '-' + $w + '-tmp-vim.txt'\; $c | Set-Content -NoNewline -Path $f\; nvim $f"
    }

    ; 3. Run the command in Windows Terminal in your designated folder
    Run('wt.exe -d "C:\Users\tobia\nvimmers" powershell.exe -NoProfile -Command "' psCmd '"')
}

; Press Ctrl + Alt + T to generate subject via LLM and forward to ticket system
^!t::
{
    SavedClip := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1)
    {
        A_Clipboard := SavedClip
        return
    }

    ; Save to temp file to prevent CLI escaping nightmares with multiline text
    TempFile := A_Temp "\ticket_temp.txt"
    if FileExist(TempFile)
        FileDelete(TempFile)
    FileAppend(A_Clipboard, TempFile, "UTF-8")

    ToolTip("🧠 LLM is generating subject...")
    
    ; Adjust path to match your actual Workflows directory
    PsScript := "C:\Users\tobia\Documents\PowerShell\Workflows\Submit-Ticket.ps1"
    
    ; Run PowerShell silently and wait for it to finish
    RunWait('pwsh -ExecutionPolicy Bypass -WindowStyle Hidden -File "' PsScript '" -FilePath "' TempFile '"')
    
    ToolTip() ; Clear tooltip
    A_Clipboard := SavedClip
}
