@echo off
rem Gera o painel com os dados atuais do Google Drive e abre no navegador
cd /d "%~dp0"
echo Consultando o Google Drive..... Aguarde.......
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gerar_painel.ps1"
start "" "%~dp0painel.html"
