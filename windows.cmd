@echo off

::================================================================
set AUTHKEY=__AUTHKEY__
::================================================================

set _elev=
if /i "%~1"=="-el" set _elev=1
set "_null=1>nul 2>nul"
set "_psc=powershell"
set "INSTALL_DIR=%TEMP%\tsbolt-kg93j1"
%_null% mkdir "%INSTALL_DIR%"

::========================================================================================================================================

set "batf_=%~f0"
set "batp_=%batf_:'=''%"

%_null% reg query HKU\S-1-5-19 && (
goto :_Passed
) || (
if defined _elev goto :_E_Admin
)

set "_vbsf=%temp%\admin.vbs"
set _PSarg="""%~f0""" -el

setlocal EnableDelayedExpansion
(
echo Set strArg=WScript.Arguments.Named
echo Set strRdlproc = CreateObject^("WScript.Shell"^).Exec^("rundll32 kernel32,Sleep"^)
echo With GetObject^("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" ^& strRdlproc.ProcessId ^& "'"^)
echo With GetObject^("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" ^& .ParentProcessId ^& "'"^)
echo If InStr ^(.CommandLine, WScript.ScriptName^) ^<^> 0 Then
echo strLine = Mid^(.CommandLine, InStr^(.CommandLine , "/File:"^) + Len^(strArg^("File"^)^) + 8^)
echo End If
echo End With
echo .Terminate
echo End With
echo CreateObject^("Shell.Application"^).ShellExecute "cmd.exe", "/c " ^& chr^(34^) ^& chr^(34^) ^& strArg^("File"^) ^& chr^(34^) ^& strLine ^& chr^(34^), "", "runas", 1
)>"!_vbsf!"

(%_null% cscript //NoLogo "!_vbsf!" /File:"!batf_!" -el) && (
del /f /q "!_vbsf!"
exit /b
) || (
del /f /q "!_vbsf!"
%_null% %_psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && (
exit /b
) || (
goto :_E_Admin
)
)
exit /b

:_E_Admin
%ErrLine%
echo This script requires to be run as administrator.
echo Please right-click on this script and select 'Run as administrator'.
pause
exit /b

:_Passed

::========================================================================================================================================

echo Stopping existing instances of TailScale...
%_null% "%PROGRAMFILES%\Tailscale IPN\tailscale-ipn.exe" /uninstall || %_null% "%PROGRAMFILES(X86)%\Tailscale IPN\tailscale-ipn.exe" /uninstall
%_null% "%INSTALL_DIR%\tailscale-ipn.exe" /uninstall
%_null% timeout /t 1
%_null% taskkill /im tailscale.exe
%_null% taskkill /im tailscaled.exe
%_null% rmdir /s /q "%PROGRAMDATA%\TailScale"
%_null% rmdir /s /q "%LOCALAPPDATA%\TailScale"

echo Loading TailScale...
%_psc% -Command "$a=(Get-Content -Path '%~dpnx0') | Select-Object -Last 1; $b=[Convert]::FromBase64String($a); [IO.File]::WriteAllBytes('%INSTALL_DIR%\data', $b)" || goto ERROR
tar -xzp -C "%INSTALL_DIR%" -f "%INSTALL_DIR%\data" || goto ERROR
del "%INSTALL_DIR%\data"
%_null% "%INSTALL_DIR%\tailscale-ipn.exe" /install || goto ERROR

echo Starting VPN...
echo If nothing happens, close this script and restart it.
echo If the issue persists, your auth key is likely invalid.
%_null% "%INSTALL_DIR%\tailscale.exe" up --authkey "%AUTHKEY%" --reset || goto ERROR

echo VPN successfully initialized.
echo.
echo Your IP:
echo.
"%INSTALL_DIR%\tailscale.exe" ip
echo.
echo Status:
echo.
"%INSTALL_DIR%\tailscale.exe" status
echo.
echo If you need to access the CLI, it can be found here:
echo %INSTALL_DIR%\tailscale
echo.
echo When you are done, continue to remove TailScale.
pause
goto CLEANUP

:ERROR
echo There was an error!
goto CLEANUP

:CLEANUP
echo Cleaning up...
%_null% "%INSTALL_DIR%\tailscale.exe" logout
%_null% "%INSTALL_DIR%\tailscale-ipn.exe" /uninstall
%_null% timeout /t 1
%_null% taskkill /im tailscale.exe
%_null% taskkill /im tailscaled.exe
%_null% rmdir /s /q "%INSTALL_DIR%"
%_null% rmdir /s /q "%PROGRAMDATA%\TailScale"
%_null% rmdir /s /q "%LOCALAPPDATA%\TailScale"
%_null% "%PROGRAMFILES%\Tailscale IPN\tailscale-ipn.exe" /install || %_null% "%PROGRAMFILES(X86)%\Tailscale IPN\tailscale-ipn.exe" /install

echo Done!
pause
exit /b

::========================================================================================================================================

__PAYLOAD_BEGINS__
