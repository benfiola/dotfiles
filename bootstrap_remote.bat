@ECHO OFF
SET ScriptDir=%~dp0
SET ScriptPath=%ScriptDir%bootstrap_remote.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%ScriptPath%'";