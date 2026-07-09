' Regenera o painel.html em segundo plano (sem janela) - usado pela tarefa agendada
Dim fso, pasta
Set fso = CreateObject("Scripting.FileSystemObject")
pasta = fso.GetParentFolderName(WScript.ScriptFullName)
CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -File """ & pasta & "\gerar_painel.ps1""", 0, False
