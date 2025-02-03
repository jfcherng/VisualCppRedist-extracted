@setlocal DisableDelayedExpansion
@echo off
set _debug=0
set vci=v0.86.0
set verbosity=/quiet
set verbshort=/qn /norestart
set auto=0
set bt32=0
set noucrt=0
set updt=0
set uc14=0
set vcpp=0
set refix=0
set installcount=0
set count=0
set invalid=0
if "%~1"=="" goto :noArg
if /i "%~1"=="/auto" (
set auto=1
set verbosity=/passive
set verbshort=/qb
)
if /i "%~1"=="/ucrt" (
set auto=1
set noucrt=1
set verbosity=/passive
set verbshort=/qb
)
if /i "%~1"=="/quiet" (
set auto=1
)
if /i "%~1"=="/vcpp" (
set auto=1
set vcpp=1
)
if /i "%~1"=="/uc14" (
set auto=1
set uc14=1
)
if /i "%~1"=="/repair" (
set auto=1
set refix=1
)
if /i "%~1"=="/drepair" (
set _debug=1
set refix=1
)
if /i "%~1"=="/update" (
set auto=1
set updt=1
)
if /i "%~1"=="/dupdate" (
set _debug=1
set updt=1
)
if /i "%~1"=="/debug" (
set _debug=1
)
if /i "%~2"=="/x86" set bt32=1

:noArg
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_temp=%temp%"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_log=%%b\VCpp"
:: if exist "%PUBLIC%\Desktop\desktop.ini" set "_log=%PUBLIC%\Desktop\VCpp"

set "arch=x64"&set "xBT=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "arch=x86"&set "xBT=x86"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "arch=arm64"&set "xBT=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "arch=arm64"&set "xBT=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "arch=x64"&set "xBT=amd64"
set wixpkg=vcredist_x86.exe,vc_redist.x86.exe,vcredist_x64.exe,vc_redist.x64.exe
if %arch%==arm64 set wixpkg=vcredist_x86.exe,vc_redist.x86.exe

set _xp=0
ver|findstr /c:" 5." >nul
if %errorlevel% equ 0 set _xp=1
if %_xp% equ 1 goto :unsupported

set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% lss 6100 goto :unsupported

if %_debug% equ 0 reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :unadmin

set "_f_=comct232.ocx msbind.dll msdbrptr.dll msstdfmt.dll comct332.ocx mscdrun.dll msflxgrd.ocx msstkprp.dll comctl32.ocx mschrt20.ocx mshflxgd.ocx mswcrun.dll comdlg32.ocx mscomct2.ocx mshtmpgr.dll mswinsck.ocx dbadapt.dll mscomctl.ocx msinet.ocx picclp32.ocx dbgrid32.ocx mscomm32.ocx msmapi32.ocx richtx32.ocx dblist32.ocx msdatgrd.ocx msmask32.ocx sysinfo.ocx mci32.ocx msdatlst.ocx msrdc20.ocx tabctl32.ocx msadodc.ocx msdatrep.ocx msrdo20.dll"

setlocal EnableDelayedExpansion
if %_debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set auto=1
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@echo off
@exit /b

:Begin
set _cwmi=0
for %%# in (wmic.exe) do if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do if "%%~$PATH:#"=="" set _pwsh=0
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set _pwsh=0
set _vbse=1
for %%# in (cscript.exe) do if "%%~$PATH:#"=="" set _vbse=0
if not exist "%SysPath%\vbscript.dll" set _vbse=0

if %uc14% equ 1 goto :ucrtonly
title Visual C++ Redistributable AIO %vci%

for /f "skip=2 tokens=3* delims= " %%G in ('"reg query "hklm\software\microsoft\Windows NT\currentversion" /v productname" %_Nul6%') do set "winv=%%G %%H"

if %winbuild% geq 7601 for /f "tokens=3" %%G in ('"reg query "hklm\software\microsoft\Windows NT\currentversion" /v UBR" %_Nul6%') do if not errorlevel 1 set /a "UBR=%%G"

if defined UBR (
for /f "skip=2 tokens=3,4,6,7 delims=. " %%G in ('reg query "hklm\software\microsoft\Windows NT\currentversion" /v buildlabex') do set "_os=%winv% %arch% {%winbuild%.%UBR%.%%J.%%I}"
) else (
for /f "skip=2 tokens=3,4,6,7 delims=. " %%G in ('reg query "hklm\software\microsoft\Windows NT\currentversion" /v buildlabex') do set "_os=%winv% %arch% {%%G.%%H.%%J.%%I}"
)

if %auto% equ 1 goto :proceed
goto :main

:proceed
pushd "!_work!"
if not exist "2010\x64\vc_red.msi" set bt32=1
if %bt32% equ 1 set wixpkg=vcredist_x86.exe,vc_redist.x86.exe

set "mvc=Microsoft Visual C++"
set "mvt=Microsoft Visual Studio 2010 Tools for Office Runtime"

set "_g_="{.*-.*-.*-.*-.*}""
set "_h_="HKEY_LOCAL_MACHINE""
set "_r_=Redistributable"
set "_l_=Additional Runtime"
set "_m_=Minimum Runtime"
set "_val=/v UninstallString"
set "_natkey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
set "_wowkey=HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
set "_msikey=HKLM\SOFTWARE\Classes\Installer\Features"
set "_rvrvt=TRIN_TRIR_SETUP"
set "_rvr09=VC_RED_enu_"
set "_rvr10=VC_RED_enu_"

set "_vervt=0.60917.0"
set "_ver08=0.50727.6229"
set "_ver09=0.30729.7523"
set "_ver10=0.40219.473"
set "_ver11=0.61135.400"
set "_ver12=0.40664.0"
set "_ver14=42.34438.0"

set "_x86codevtc=2201E8883DC9CA23EBB666F86FBA1A63"
set "_x86code09c=6E815EB96CCE9A53884E7857C57002F0"
set "_x86code10c=1D5E3C0FEDA1E123187686FED06E995A"
set "_x86codevt={888E1022-9CD3-32AC-BE6B-668FF6ABA136}"
set "_x86code08={710f4c1c-cc18-4c49-8cbf-51240c89a1a2}"
set "_x86code09={9BE518E6-ECC6-35A9-88E4-87755C07200F}"
set "_x86code10={F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}"
set "_x86code11m={BD95A8CD-1D9F-35AD-981A-3E7925026EBB}"
set "_x86code11a={B175520C-86A2-35A7-8619-86DC379688B9}"
set "_x86code12m={8122DAB1-ED4D-3676-BB0A-CA368196543E}"
set "_x86code12a={D401961D-3A20-3AC7-943B-6139D5BD490A}"
set "_x86code14m={5D0C4511-3CA1-4FF8-A4BA-C0E1957ABEEA}"
set "_x86code14a={A5592FEF-F948-4BA6-A066-8BBFC2DC7EE1}"

set "_x64codevtc=9D7840160643A823393312D9347AC55C"
set "_x64code09c=67D6ECF5CD5FBA732B8B22BAC8DE1B4D"
set "_x64code10c=1926E8D15D0BCE53481466615F760A7F"
set "_x64codevt={610487D9-3460-328A-9333-219D43A75CC5}"
set "_x64code08={ad8a2fa1-06e7-4b0d-927d-6e54b3d31028}"
set "_x64code09={5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}"
set "_x64code10={1D8E6291-B0D5-35EC-8441-6616F567A0F7}"
set "_x64code11m={CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}"
set "_x64code11a={37B8F9C7-03FB-3253-8781-2517C99D7C00}"
set "_x64code12m={53CF6934-A98D-3D84-9146-FC4EDF3D5641}"
set "_x64code12a={010792BA-551A-3AC0-A7EF-0FAB4156C382}"
set "_x64code14m={2E15F519-4FDA-4834-B4EE-7EFCE7D8D4EE}"
set "_x64code14a={E528AD94-12D7-42C4-91A3-908BE28E9BD2}"

set "_pathvt=%CommonProgramFiles%\Microsoft Shared\VSTO"
if defined CommonProgramW6432 set "_pathvt=%CommonProgramW6432%\Microsoft Shared\VSTO"
set "_filevt=%_pathvt%\vstoee.dll"

set "_x86wsxs08=x86_microsoft.vc80.openmp_1fc8b3b9a1e18e3b"
set "_x86wsxs09=x86_microsoft.vc90.openmp_1fc8b3b9a1e18e3b"
set "_x86fusn08=x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_none_bcc8f3fc9457ed28\8.0\8.0.50727.6229\msvcp80.dll"
set "_x86fusn09=x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_none_ea33c8f0b247cd77\9.0\9.0.30729.7523\msvcp90.dll"
set "_x86file08=x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_8.0.50727.6229_none_d089f796442de10e\msvcp80.dll"
set "_x86file09=x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_9.0.30729.7523_none_508f21ccbcbbb7a8\msvcp90.dll"
set "_x86file10=msvcp100.dll"
set "_x86file11=msvcp110.dll"
set "_x86file12=msvcp120.dll"
set "_x86file14=msvcp140.dll"

set "_x64wsxs08=amd64_microsoft.vc80.openmp_1fc8b3b9a1e18e3b"
set "_x64wsxs09=amd64_microsoft.vc90.openmp_1fc8b3b9a1e18e3b"
set "_x64fusn08=amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_none_751bbd257fdbc422\8.0\8.0.50727.6229\msvcp80.dll"
set "_x64fusn09=amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_none_a28692199dcba471\9.0\9.0.30729.7523\msvcp90.dll"
set "_x64file08=amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_8.0.50727.6229_none_88dcc0bf2fb1b808\msvcp80.dll"
set "_x64file09=amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_9.0.30729.7523_none_08e1eaf5a83f8ea2\msvcp90.dll"
set "_x64file10=msvcp100.dll"
set "_x64file11=msvcp110.dll"
set "_x64file12=msvcp120.dll"
set "_x64file14=msvcp140.dll"

if exist filever.vbs del /f /q filever.vbs
echo>>filever.vbs Set objFSO = CreateObject^("Scripting.FileSystemObject"^)
echo>>filever.vbs Wscript.Echo objFSO.GetFileVersion^(WScript.arguments^(0^)^)

set "_WSH=SOFTWARE\Microsoft\Windows Script Host\Settings"
if %_vbse% equ 1 (
reg query "HKCU\%_WSH%" /v Enabled %_Nul2% | find /i "0x0" %_Nul1% && (set vbscu=1&reg delete "HKCU\%_WSH%" /v Enabled /f %_Nul3%)
reg query "HKLM\%_WSH%" /v Enabled %_Nul2% | find /i "0x0" %_Nul1% && (set vbslm=1&reg delete "HKLM\%_WSH%" /v Enabled /f %_Nul3%)
)

:WiXWow
if %arch%==x86 goto :WiXNat

if exist "!_temp!\msi.txt" del /f /q "!_temp!\msi.txt"
if exist "!_temp!\wix.txt" del /f /q "!_temp!\wix.txt"

if %_debug% equ 0 call :title

call :chMSI wow

call :chWiX wow

findstr /i %_h_% "!_temp!\wix.txt" %_Nul3% || goto :MsiWow

for %%G in (11,12,14) do if !_x86install%%G! equ 0 (
call :reMSI wow %%G
)

call :unWiX wow

:MsiWow
if %_debug% equ 0 call :title

findstr /i %_h_% "!_temp!\msi.txt" %_Nul3% || goto :WiXNat

call :unMSI wow

:WiXNat
set only32=0
if %arch%==arm64 set only32=1
if not %arch%==x86 if %bt32% equ 1 set only32=1

if %only32% equ 1 (
for %%G in (08,09,10,11,12,14,vt) do set _%arch%install%%G=0
goto :process
)

if exist "!_temp!\msi.txt" del /f /q "!_temp!\msi.txt"
if exist "!_temp!\wix.txt" del /f /q "!_temp!\wix.txt"

if %_debug% equ 0 call :title

call :chMSI nat

if not %arch%==x86 goto :MsiNat

call :chWiX nat

findstr /i %_h_% "!_temp!\wix.txt" %_Nul3% || goto :MsiNat

for %%G in (11,12,14) do if !_x86install%%G! equ 0 (
call :reMSI nat %%G
)

call :unWiX nat

:MsiNat
if %_debug% equ 0 call :title

findstr /i %_h_% "!_temp!\msi.txt" %_Nul3% || goto :process

call :unMSI nat

:process
set "_x86msivt=vstor\vstor40_x86.msi"
set "_x64msivt=vstor\vstor40_x64.msi"
set "_x86msi08=2005\x86\vcredist.msi"
set "_x64msi08=2005\x64\vcredist.msi"
set "_x86msi09=2008\x86\vc_red.msi"
set "_x64msi09=2008\x64\vc_red.msi"
set "_x86msi10=2010\x86\vc_red.msi"
set "_x64msi10=2010\x64\vc_red.msi"
set "_x86msi11m=2012\x86\vc_runtimeMinimum_x86.msi"
set "_x86msi11a=2012\x86\vc_runtimeAdditional_x86.msi"
set "_x64msi11m=2012\x64\vc_runtimeMinimum_x64.msi"
set "_x64msi11a=2012\x64\vc_runtimeAdditional_x64.msi"
set "_x86msi12m=2013\x86\vc_runtimeMinimum_x86.msi"
set "_x86msi12a=2013\x86\vc_runtimeAdditional_x86.msi"
set "_x64msi12m=2013\x64\vc_runtimeMinimum_x64.msi"
set "_x64msi12a=2013\x64\vc_runtimeAdditional_x64.msi"
set "_x86msi14m=2022\x86\vc_runtimeMinimum_x86.msi"
set "_x86msi14a=2022\x86\vc_runtimeAdditional_x86.msi"
set "_x64msi14m=2022\x64\vc_runtimeMinimum_x64.msi"
set "_x64msi14a=2022\x64\vc_runtimeAdditional_x64.msi"
set "_vbcrun=vbc\vbcrun.msi"
set "_vcrun=vbc\vcrun.msi"
set "_vbrun=vbc\vbrun.msi"

for %%G in (08,09,10) do if !_%arch%install%%G! equ 1 (
if exist "!_%arch%msi%%G!" set /a installcount+=1
)
for %%G in (11,12,14) do if !_%arch%install%%G! equ 1 (
if exist "!_%arch%msi%%Gm!" set /a installcount+=1
if exist "!_%arch%msi%%Ga!" set /a installcount+=1
)
if not %arch%==x86 for %%G in (08,09,10) do if !_x86install%%G! equ 1 (
if exist "!_x86msi%%G!" set /a installcount+=1
)
if not %arch%==x86 for %%G in (11,12,14) do if !_x86install%%G! equ 1 (
if exist "!_x86msi%%Gm!" set /a installcount+=1
if exist "!_x86msi%%Ga!" set /a installcount+=1
)
if %vcpp% equ 0 if !_%arch%installvt! equ 1 (
if exist "!_%arch%msivt!" set /a installcount+=1
)

if %installcount% equ 0 goto :chVBC

for %%G in (08,09,10) do if !_%arch%install%%G! equ 1 (
call :install "!_%arch%msi%%G!"
)
for %%G in (11,12,14) do if !_%arch%install%%G! equ 1 (
call :install "!_%arch%msi%%Gm!"
call :install "!_%arch%msi%%Ga!"
)
if not %arch%==x86 for %%G in (08,09,10) do if !_x86install%%G! equ 1 (
call :install "!_x86msi%%G!"
)
if not %arch%==x86 for %%G in (11,12,14) do if !_x86install%%G! equ 1 (
call :install "!_x86msi%%Gm!"
call :install "!_x86msi%%Ga!"
)
if %vcpp% equ 0 if !_%arch%installvt! equ 1 (
call :install "!_%arch%msivt!"
)
goto :chVBC

:install
if %_debug% equ 0 call :title
set /a count+=1
echo Installing %count% of %installcount%: %~1
echo.
echo.
if %_debug% equ 0 %~1 %verbshort%
goto :eof

:chVBC
if %arch%==x86 (
set "dest=%SystemRoot%\system32"
set "_cpf=%CommonProgramFiles%\DESIGNER"
set "_qkey=%_natkey%"
) else (
set "dest=%SystemRoot%\syswow64"
set "_cpf=%CommonProgramFiles(x86)%\DESIGNER"
set "_qkey=%_wowkey%"
)
if %vcpp% equ 1 if exist "%dest%\msvcrt10.dll" (
if %installcount% equ 0 if %invalid% equ 0 (call :title&echo All installed Visual C++ Redistributables are compliant.)
goto :close
)
if %updt% equ 1 (
if %installcount% equ 0 if %invalid% equ 0 (call :title&echo Installed Visual C++ Redistributables are compliant.)
goto :close
)
set "_vbc_={C5E3A69D-D391-45A6-A8FB-00B01E2B010D}"
set "_vco_={C5E3A69D-D392-45A6-A8FB-00B01E2B010D}"
set "_vbo_={C5E3A69D-D393-45A6-A8FB-00B01E2B010D}"
set skpVB=1
reg query %_qkey%\%_vbc_% %_val% %_Nul3% && (
if %refix% equ 1 (goto :vbcinstall) else (goto :ucrtbase)
)
reg query %_qkey%\%_vco_% %_val% %_Nul3% && reg query %_qkey%\%_vbo_% %_val% %_Nul3% && (
if %refix% equ 1 set skpVB=0
if %refix% equ 1 (goto :vcinstall) else (goto :ucrtbase)
)
reg query %_qkey%\%_vco_% %_val% %_Nul3% && if %vcpp% equ 1 (
if %refix% equ 1 (goto :vcinstall) else (goto :ucrtbase)
)
if %vcpp% equ 1 (
goto :vcinstall
)
if not exist "%dest%\vb40032.dll" goto :vbcinstall
if %_debug% equ 0 if exist "%dest%\msvbvm50.dll" (
regsvr32 /u /s %dest%\msvbvm50.dll %_Nul3%
reg add HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application\VBRuntime /v EventMessageFile /t REG_SZ /d %dest%\msvbvm60.dll /f %_Nul3%
reg add HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application\VBRuntime /v TypesSupported /t REG_DWORD /d 4 /f %_Nul3%
reg import vbc\extra-fix-%arch%.reg %_Nul3%
)
for %%G in (
%_f_%
) do if exist "%dest%\%%G" (
if %_debug% equ 0 (%_Nul3% regsvr32 /u /s %dest%\%%G) else (echo %%G)
)
for %%G in (
mscdrun.dll mshtmpgr.dll mswcrun.dll
) do if exist "%_cpf%\%%G" (
if %_debug% equ 0 (%_Nul3% regsvr32 /u /s "%_cpf%\%%G") else (echo %%G)
)
for %%G in (
atl70.dll atl71.dll msvcrt10.dll vb40032.dll %dest%\mfc70*.dll %dest%\mfc71*.dll %dest%\msvc*70.dll %dest%\msvc*71.dll
%_f_%
) do if exist "%dest%\%%~nxG" (
if %_debug% equ 0 (del /f /q "%dest%\%%~nxG" %_Nul3%)
)
for %%G in (
mscdrun.dll mshtmpgr.dll mswcrun.dll
) do if exist "%_cpf%\%%G" (
if %_debug% equ 0 (del /f /q "%_cpf%\%%~nxG" %_Nul3%)
)
if %_debug% equ 0 if exist "%dest%\msvbvm50.dll" del /f /q %dest%\msvbvm50.dll %_Nul3%
if %_debug% equ 0 if %arch%==x86 (
del /f /q %SystemRoot%\System\vb40016.dll %_Nul3%
del /f /q %SystemRoot%\System\vbrun*.dll %_Nul3%
)

:vbcinstall
if not exist "%_vbcrun%" goto :ucrtbase
if %_debug% equ 0 call :title
set /a count+=1
set /a installcount+=1
echo Installing %count% of %installcount%: %_vbcrun%
echo.
echo.
if %_debug% equ 0 (
if %refix% equ 1 start /wait MsiExec.exe /X%_vbc_% %verbosity% /norestart
start /wait MsiExec.exe /X%_vco_% %verbosity% /norestart
start /wait MsiExec.exe /X%_vbo_% %verbosity% /norestart
%_vbcrun% %verbshort%
)
goto :ucrtbase

:vcinstall
if not exist "%_vcrun%" goto :ucrtbase
if %_debug% equ 0 call :title
set /a count+=1
set /a installcount+=1
echo Installing %count% of %installcount%: %_vcrun%
echo.
echo.
if %_debug% equ 0 (
start /wait MsiExec.exe /X%_vbc_% %verbosity% /norestart
if %refix% equ 1 start /wait MsiExec.exe /X%_vco_% %verbosity% /norestart
%_vcrun% %verbshort%
)
if %skpVB% equ 1 goto :ucrtbase

:vbinstall
if not exist "%_vbrun%" goto :ucrtbase
if %_debug% equ 0 call :title
set /a count+=1
set /a installcount+=1
echo Installing %count% of %installcount%: %_vbrun%
echo.
echo.
if %_debug% equ 0 (
start /wait MsiExec.exe /X%_vbo_% %verbosity% /norestart
%_vbrun% %verbshort%
)

:ucrtbase
if %installcount% equ 0 if %invalid% equ 0 (call :title&echo All installed Visual C++ Redistributables are compliant.)
if %noucrt% equ 1 goto :close
:ucrtonly
if exist "%SysPath%\ucrtbase.dll" goto :close
if %_debug% equ 1 goto :close
set "dest=%SystemRoot%\servicing\Packages"
if exist "%dest%\Microsoft-Windows-*6.1.7601.17514.mum" (
dism.exe /Online /Quiet /NoRestart /Add-Package /PackagePath:ucrt\7601-%arch%.mum %_Nul3%
)
if exist "%dest%\Microsoft-Windows-*6.2.9200.16384.mum" (
dism.exe /Online /Quiet /NoRestart /Add-Package /PackagePath:ucrt\9200-%arch%.mum %_Nul3%
)
if exist "%dest%\Package_for_KB2919355*6.3.1.14.mum" (
dism.exe /Online /Quiet /NoRestart /Add-Package /PackagePath:ucrt\9600-%arch%.mum %_Nul3%
)

:close
for %%G in (
"!_temp!\*Redistributable*.*"
"!_temp!\*vcredist*.*"
"!_temp!\*vstor*.*"
"!_temp!\msi*.log"
"!_temp!\del*.tmp"
msi.txt wix.txt
) do (
if exist "!_temp!\%%~nxG" del /f /q "!_temp!\%%~nxG"
)
if exist filever.vbs del /f /q filever.vbs
if defined vbscu reg add "HKCU\%_WSH%" /v Enabled /t REG_DWORD /d 0 /f %_Nul3%
if defined vbslm reg add "HKLM\%_WSH%" /v Enabled /t REG_DWORD /d 0 /f %_Nul3%

if %auto% equ 1 goto :eof
if %installcount% neq 0 (
if %_debug% equ 0 call :title
echo Installer has completed. 
)
echo.
echo.
goto :E_Exit

:reMSI
if "%1"=="nat" (
set _k_=%_natkey%
) else (
set _k_=%_wowkey%
)

if "%2"=="11" for %%G in (
"%mvc% 2012 %_r_%"
) do (
reg query %_k_% /f %%G /s %_Nul2% | find /i %_h_% | findstr /r %_g_% %_Nul1% && (set _x86install%2=1)
)
if "%2"=="12" for %%G in (
"%mvc% 2013 %_r_%"
) do (
reg query %_k_% /f %%G /s %_Nul2% | find /i %_h_% | findstr /r %_g_% %_Nul1% && (set _x86install%2=1)
)
if "%2"=="14" for %%G in (
"%mvc% 2015 %_r_%"
"%mvc% 2017 %_r_%"
"%mvc% 2019 %_r_%"
"%mvc% 2015-2019 %_r_%"
"%mvc% 2015-2022 %_r_%"
) do (
reg query %_k_% /f %%G /s %_Nul2% | find /i %_h_% | findstr /r %_g_% %_Nul1% && (set _x86install%2=1)
)

goto :eof

:chWiX
if "%1"=="nat" (
set _k_=%_natkey%
) else (
set _k_=%_wowkey%
)

for %%G in (
"%mvc% 2012 %_r_%"
"%mvc% 2013 Preview %_r_%"
"%mvc% 2013 RC %_r_%"
"%mvc% 2013 %_r_%"
"%mvc% 14 CTP %_r_%"
"%mvc% 2015 Preview %_r_%"
"%mvc% 2015 CTP %_r_%"
"%mvc% 2015 RC %_r_%"
"%mvc% 2015 %_r_%"
"%mvc% 2017 RC %_r_%"
"%mvc% 2017 %_r_%"
"%mvc% 2019 %_r_%"
"%mvc% 2022 %_r_%"
"%mvc% 2015-2019 %_r_%"
"%mvc% 2015-2022 %_r_%"
) do (
reg query %_k_% /f %%G /s %_Nul2% | find /i %_h_% | findstr /r %_g_% >>"!_temp!\wix.txt"
)

goto :eof

:chMSI
if "%1"=="nat" (
set _a_=%arch%
set _k_=%_natkey%
set _e_=%SysPath%
set _p_=%SystemRoot%\System32
) else (
set _a_=x86
set _k_=%_wowkey%
set _e_=%SystemRoot%\SysWOW64
set _p_=%SystemRoot%\SysWOW64
)

set vvv=1
if %updt% equ 1 set vvv=2
if %refix% equ 1 set vvv=3
for %%G in (08,09,10,11,12,14,vt) do set _%_a_%install%%G=%vvv%

if not "%1"=="nat" goto :skipvt
if %vcpp% equ 1 goto :skipvt

if exist "%_filevt%" (
call :fVer "%_filevt%" _%_a_%installvt !_vervt!
)

reg query %_k_%\!_%_a_%codevt! %_val% %_Nul3% && (if %refix% equ 1 set _%_a_%installvt=1) || (if !_%_a_%installvt! equ 0 set _%_a_%installvt=1)
reg query %_msikey%\!_%_a_%codevtc! %_Nul2% | find /i "!_rvrvt!" %_Nul1% && set _%_a_%installvt=1
if exist "%_pathvt%\10.0\%mvt% (%_a_%)\install.exe" set _%_a_%installvt=1

call :chREG1 vt vt

:skipvt
for %%G in (10,11,12,14) do if exist "%_e_%\!_%_a_%file%%G!" (
call :fVer "%_p_%\!_%_a_%file%%G!" _%_a_%install%%G !_ver%%G!
)
for %%G in (08,09) do (
dir /b "%SystemRoot%\WinSxS\!_%_a_%wsxs%%G!_*" %_Nul2% | findstr /v /c:"!_ver%%G!" %_Nul1% && (if %updt% equ 1 set _%_a_%install%%G=1)
dir /b "%SystemRoot%\WinSxS\Fusion\!_%_a_%wsxs%%G!_*" %_Nul2% | findstr /v /c:"!_ver%%G!" %_Nul1% && (if %updt% equ 1 set _%_a_%install%%G=1)
if exist "%SystemRoot%\WinSxS\!_%_a_%file%%G!" (if %refix% equ 1 (set _%_a_%install%%G=1) else (set _%_a_%install%%G=0))
if exist "%SystemRoot%\WinSxS\Fusion\!_%_a_%fusn%%G!" (if %refix% equ 1 (set _%_a_%install%%G=1) else (set _%_a_%install%%G=0))
)
for %%G in (08,09,10) do (
reg query %_k_%\!_%_a_%code%%G! %_val% %_Nul3% && (if %refix% equ 1 set _%_a_%install%%G=1) || (if !_%_a_%install%%G! equ 0 set _%_a_%install%%G=1)
if defined _rvr%%G reg query %_msikey%\!_%_a_%code%%Gc! %_Nul2% | find /i "!_rvr%%G!" %_Nul1% && set _%_a_%install%%G=1
)
for %%G in (11,12,14) do (
reg query %_k_%\!_%_a_%code%%Gm! %_val% %_Nul3% && (if %refix% equ 1 set _%_a_%install%%G=1) || (if !_%_a_%install%%G! equ 0 set _%_a_%install%%G=1)
reg query %_k_%\!_%_a_%code%%Ga! %_val% %_Nul3% && (if %refix% equ 1 set _%_a_%install%%G=1) || (if !_%_a_%install%%G! equ 0 set _%_a_%install%%G=1)
)

for %%G in ("08 2005","09 2008","10 2010") do (
call :chREG1 %%~G
)
for %%G in ("11 2012","12 2013","14 2022") do (
call :chREG2 %%~G
)
for %%G in (
"%mvc% 14 %_a_% %_l_%"
"%mvc% 14 %_a_% %_m_%"
"%mvc% 2015 %_a_% %_l_%"
"%mvc% 2015 %_a_% %_m_%"
"%mvc% 2017 %_a_% %_l_%"
"%mvc% 2017 %_a_% %_m_%"
"%mvc% 2019 %_a_% %_l_%"
"%mvc% 2019 %_a_% %_m_%"
) do (
reg query %_k_% /f %%G /s %_Nul2% | find /i %_h_% | findstr /r %_g_% >>"!_temp!\msi.txt"
)

goto :eof

:fVer
if %_debug% equ 1 cmd.exe /c "dir %1 | find /i "%~n1""
if %refix% equ 1 (
set %2=1
goto :eof
)
set "_fvr=%~1"
set "cfvr=!_fvr:\=\\!"
if %_vbse% equ 1 (
set _chk=cscript.exe //nologo filever.vbs "%_fvr%"
) else if %_pwsh% equ 1 (
set _chk=powershell -nop -c "(gi '%_fvr%').VersionInfo.FileVersion"
) else if %_cwmi% equ 1 (
set "_chk="wmic datafile where name='!cfvr!' get Version /value ^| findstr ^=""
) else (
goto :eof
)
if %updt% equ 1 set %2=1
set min=0&set bld=0&set rev=0
for /f "tokens=2-4 delims=. " %%i in ('%_chk%') do (
set min=%%i&set bld=%%j&set rev=%%k
)
for /f "tokens=1-3 delims=." %%i in ('echo %3') do (
if %min% gtr %%i set %2=0
if %min% equ %%i if %bld% gtr %%j set %2=0
if %min% equ %%i if %bld% equ %%j if %rev% geq %%k set %2=0
)
goto :eof

:chREG1
set _v_=%1
set _y_=%mvc% %2
if "%2"=="vt" set _y_=%mvt%
if !_%_a_%install%_v_%! neq 1 if !_%_a_%install%_v_%! neq 3 (
reg query %_k_% /f "%_y_% %_r_%" /s %_Nul2% | find /i %_h_% | findstr /r %_g_% | findstr /i /v !_%_a_%code%_v_%! >>"!_temp!\msi.txt"
)
if !_%_a_%install%_v_%! neq 0 if !_%_a_%install%_v_%! neq 2 (
reg query %_k_% /f "%_y_% %_r_%" /s %_Nul2% | find /i %_h_% | findstr /r %_g_% >>"!_temp!\msi.txt"
)
goto :eof

:chREG2
set _v_=%1
set _y_=%mvc% %2
if !_%_a_%install%_v_%! neq 1 if !_%_a_%install%_v_%! neq 3 (
reg query %_k_% /f "%_y_% %_a_% %_l_%" /s %_Nul2% | find /i %_h_% | findstr /r %_g_% | findstr /i /v !_%_a_%code%_v_%a! >>"!_temp!\msi.txt"
reg query %_k_% /f "%_y_% %_a_% %_m_%" /s %_Nul2% | find /i %_h_% | findstr /r %_g_% | findstr /i /v !_%_a_%code%_v_%m! >>"!_temp!\msi.txt"
)
if !_%_a_%install%_v_%! neq 0 if !_%_a_%install%_v_%! neq 2 (
reg query %_k_% /f "%_y_% %_a_% %_l_%" /s %_Nul2% | find /i %_h_% | findstr /r %_g_% >>"!_temp!\msi.txt"
reg query %_k_% /f "%_y_% %_a_% %_m_%" /s %_Nul2% | find /i %_h_% | findstr /r %_g_% >>"!_temp!\msi.txt"
)
goto :eof

:unWiX
if "%1"=="nat" (
set _k_=%_natkey%
set _t_=x86
set _c_=7
set _p_=vcredist_x86.exe,vc_redist.x86.exe
) else (
set _k_=%_wowkey%
set _t_=x64/x86
set _c_=8
set _p_=%wixpkg%
)

echo Uninstalling non-compliant Visual C++ WiX packages {%_t_%}
echo ^(please wait as this process may take a few moments^)

set invalid=1
for /f "usebackq tokens=%_c_% delims=\" %%G in ("!_temp!\wix.txt") do (
for %%H in (%_p_%) do (
  if exist "%ProgramData%\Package Cache\%%G\%%H" (
    if %_debug% equ 0 (
      start /wait "" "%ProgramData%\Package Cache\%%G\%%H" /uninstall %verbosity% /norestart
      reg delete %_k_%\%%G /f %_Nul3%
      )
    )
  )
)

goto :eof

:unMSI
if "%1"=="nat" (
set _k_=%_natkey%
set _t_=%arch%
set _c_=7
) else (
set _k_=%_wowkey%
set _t_=x86
set _c_=8
)

echo Uninstalling non-compliant Visual C++ MSI packages {%_t_%}
echo ^(please wait as this process may take a few moments^)

set invalid=1
for /f "usebackq tokens=%_c_% delims=\" %%G in ("!_temp!\msi.txt") do (
reg query %_k_%\%%G %_val% %_Nul3% && if %_debug% equ 0 (
  start /wait MsiExec.exe /X%%G %verbosity% /norestart
  reg delete %_k_%\%%G /f %_Nul3%
  )
)

goto :eof

:title
if %_debug% equ 1 goto :eof
@cls
echo -----------------------------------------
echo Installer for Visual C++ Runtimes %vci%
echo -----------------------------------------
echo %_os%
echo.
goto :eof

:unadmin
echo ==== ERROR ====
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
if %auto% equ 1 goto :eof
goto :E_Exit

:unsupported
if %auto% equ 1 goto :eof
if %_debug% equ 1 goto :eof
if %_xp% equ 1 (
set "_tag=Windows XP"
set "_rpv=v35"
set "_vcv=2019 v14.28.29213.0"
) else (
set "_tag=Windows Vista"
set "_rpv=v61"
set "_vcv=2022 v14.32.31332.0"
)
echo ==== Notice ====
echo VisualCppRedist_AIO %_rpv% is the last version to support %_tag%
echo VC++ %_vcv% is the last version compatible with %_tag%
goto :E_Exit

:E_Exit
echo.
echo Press any key to exit.
pause >nul
exit /b

:main
if %_debug% equ 1 goto :proceed
set _inp=
if %_debug% equ 0 call :title
echo Before installing the latest Visual C++ Runtimes
echo any existing non-compliant versions will be removed.
echo.
echo These include the original EXE installers or the MSI packages
echo with a version lower than the ones bundled with this Installer.
echo.
echo Proceed with the check/removal and installation?
echo.
echo ----------------------------------------------------------
choice /c YRN /n /m "Press Y for Yes, R for ReadMe, or N to cancel and exit> "
if errorlevel 3 goto :eof
if errorlevel 2 goto :readme
if errorlevel 1 goto :proceed
goto :main

:readme
set _inp=
@cls
echo ----------------------------------------
echo Overview:
echo ----------------------------------------
echo.
echo AIO Repack for latest Microsoft Visual C++ Runtimes
echo without the original setup bloat payload.
echo.
echo Automatically installs the latest available Redistributables for:
echo - Visual C++: 2005, 2008, 2010, 2012, 2013, 2022 ^(2019-2015^)
echo - Visual Studio 2010 Tools for Office Runtime
echo.
echo Additionally, installs these old x86 runtimes:
echo - Visual C++: 2002, 2003
echo - Visual Basic Runtimes
echo.
echo Before installation, the script needs to check and remove
echo existing non-compliant Visual C++ Runtimes.
echo.
echo ----------------------------------------------------------
choice /c NM /N /M "N - Next page, M - Return to Installer"
if errorlevel 2 goto :main
if errorlevel 1 goto :page2
goto :readme

:page2
set _inp=
@cls
echo ----------------------------------------
echo Credits:
echo ----------------------------------------
echo.
echo @ricktendo64 / repacks.net - wincert.net
echo VBCRedist_AIO_x86_x64.exe creator,  modded MSI installers
echo.
echo @burfadel / MDL forums - @thatguy91 / guru3D Forums
echo original installation script
echo.
echo Latest AIO Repack release can be found at:
echo https://tiny.cc/vcredist
echo https://github.com/abbodi1406/vcredist/releases
echo.
echo.
echo Visual Studio is a registered trademark of Microsoft Corporation.
echo.
echo ---------------------------------------------------------------
choice /c PLM /N /M "P - Previous Page, L - Open release link, M - Return to Installer"
if errorlevel 3 goto :main
if errorlevel 2 start https://tiny.cc/vcredist&goto :page2
if errorlevel 1 goto :readme
goto :page2