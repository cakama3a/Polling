@echo off
setlocal EnableDelayedExpansion

:: =====================================================================
:: CONFIGURATION - Change these parameters as needed
:: =====================================================================
:: OUTPUT_NAME will be set dynamically as the folder name
set "USE_NOCONSOLE=false"                     :: Change to true to hide console

:: --- Other Build Options ---
set "REQUIRED_PACKAGES=pygame numpy requests colorama pillow" :: Required Python packages 
set "USE_PYARMOR=false"                      :: Use PyArmor for code obfuscation? 
set "PYARMOR_OPTIONS="                       :: PyArmor options (empty for basic license) 
:: =====================================================================

:: Set CMD encoding to UTF-8
chcp 65001 >nul

:: Initialize SIGN_WITH_YUBIKEY to false by default
set "SIGN_WITH_YUBIKEY=false"

:: Prompt user to choose whether to sign the program
echo.
echo =====================================================================
echo YubiKey Signing Option
echo =====================================================================
echo Do you want to sign the executable with a YubiKey?
echo WARNING: Signing should only be performed by the script author.
echo If you are a regular user, choose 'No' (default).
echo.
:sign_prompt
set "SIGN_CHOICE="
set /p SIGN_CHOICE=Enter 'Yes' or 'No' (default is 'No'): 
:: Trim spaces and validate input
set "SIGN_CHOICE=%SIGN_CHOICE: =%"
if /i "!SIGN_CHOICE!"=="Yes" (
    set "SIGN_WITH_YUBIKEY=true"
) else if /i "!SIGN_CHOICE!"=="No" (
    set "SIGN_WITH_YUBIKEY=false"
) else if "!SIGN_CHOICE!"=="" (
    set "SIGN_WITH_YUBIKEY=false"
) else (
    echo Invalid input. Please enter 'Yes' or 'No'.
    goto sign_prompt
)
echo User chose: !SIGN_CHOICE!
echo SIGN_WITH_YUBIKEY is set to: !SIGN_WITH_YUBIKEY!
echo.

:: Redirect all output to a log file and console
set "LOG_FILE=%~dp0build_log.txt"
echo Build started at %DATE% %TIME% > "%LOG_FILE%"
echo Build started at %DATE% %TIME%
echo User chose: !SIGN_CHOICE! >> "%LOG_FILE%"
echo SIGN_WITH_YUBIKEY is set to: !SIGN_WITH_YUBIKEY! >> "%LOG_FILE%"

:: Clean up old temporary directories
echo Cleaning up old temporary directories...
echo Cleaning up old temporary directories... >> "%LOG_FILE%"
for /d %%D in ("%TEMP%\%OUTPUT_NAME%Build_*") do rd /s /q "%%D" 2>nul

:: Path variables setup
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%F in ("%SCRIPT_DIR%") do set "OUTPUT_NAME=%%~nxF"
echo Using OUTPUT_NAME: %OUTPUT_NAME%
echo Using OUTPUT_NAME: %OUTPUT_NAME% >> "%LOG_FILE%"

set "PYTHON_SCRIPT=%SCRIPT_DIR%\Python.py"
set "ICON_PNG_PATH=%SCRIPT_DIR%\icon.png"
set "TEMP_DIR=%TEMP%\%OUTPUT_NAME%Build_%RANDOM%"
set "ICON_ICO_PATH=%TEMP_DIR%\icon.ico"
set "EXE_PATH=%TEMP_DIR%\dist\%OUTPUT_NAME%.exe"
set "FINAL_EXE_PATH=%SCRIPT_DIR%\%OUTPUT_NAME%.exe"
set "OBFUSCATED_DIR=%TEMP_DIR%\obfuscated"
set "OBFUSCATED_SCRIPT=%OBFUSCATED_DIR%\Python.py"

:: Check if Python.py exists
if not exist "%PYTHON_SCRIPT%" (
    echo Error: File %PYTHON_SCRIPT% not found!
    echo Error: File %PYTHON_SCRIPT% not found! >> "%LOG_FILE%"
    pause
    exit /b 1
)

:: Universal Python search
set "PYTHON="
where py >nul 2>nul && set "PYTHON=py" || where python >nul 2>nul && set "PYTHON=python"
if "%PYTHON%"=="" (
    echo Error: Python not found! Make sure Python is installed and added to PATH.
    echo Error: Python not found! >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo Found Python executable: %PYTHON%
echo Found Python executable: %PYTHON% >> "%LOG_FILE%"

:: Create and activate virtual environment
echo Creating virtual environment...
echo Creating virtual environment... >> "%LOG_FILE%"
set "VENV_DIR=%TEMP_DIR%\venv"
%PYTHON% -m venv "%VENV_DIR%" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create virtual environment!
    echo Error: Failed to create virtual environment! >> "%LOG_FILE%"
    pause
    exit /b 1
)
call "%VENV_DIR%\Scripts\activate.bat"

:: Install packages
echo Installing packages: %REQUIRED_PACKAGES% pyinstaller
echo Installing packages: %REQUIRED_PACKAGES% pyinstaller >> "%LOG_FILE%"
pip install --upgrade pip >> "%LOG_FILE%" 2>&1
pip install %REQUIRED_PACKAGES% pyinstaller >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to install packages!
    echo Error: Failed to install packages! >> "%LOG_FILE%"
    pause
    exit /b 1
)

:: Convert PNG to ICO
if exist "%ICON_PNG_PATH%" (
    echo Converting icon.png to icon.ico...
    echo Converting icon.png to icon.ico... >> "%LOG_FILE%"
    python -c "from PIL import Image; img = Image.open(r'%ICON_PNG_PATH%'); img.save(r'%ICON_ICO_PATH%', 'ICO')" >> "%LOG_FILE%" 2>&1
)

:: Form PyInstaller command
set "PYINSTALLER_CMD=pyinstaller --clean --onefile --log-level INFO"
if "%USE_NOCONSOLE%"=="true" set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --noconsole"
if exist "%ICON_ICO_PATH%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --icon="%ICON_ICO_PATH%""
) else if exist "%ICON_PNG_PATH%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --icon="%ICON_PNG_PATH%""
)
if exist "%ICON_PNG_PATH%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --add-data="%ICON_PNG_PATH%;.""
)
:: Use PIL instead of pillow for hidden import
for %%P in (%REQUIRED_PACKAGES%) do (
    if "%%P"=="pillow" (
        set "PYINSTALLER_CMD=!PYINSTALLER_CMD! --hidden-import=PIL"
    ) else (
        set "PYINSTALLER_CMD=!PYINSTALLER_CMD! --hidden-import=%%P"
    )
)
set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --workpath="%TEMP_DIR%\build" --distpath="%TEMP_DIR%\dist" --specpath="%TEMP_DIR%""
set "PYINSTALLER_CMD=%PYINSTALLER_CMD% -n "%OUTPUT_NAME%" "%PYTHON_SCRIPT%""

:: Execute PyInstaller
echo Running PyInstaller...
echo Running PyInstaller... >> "%LOG_FILE%"
%PYINSTALLER_CMD% >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: PyInstaller failed! Check log for details.
    echo Error: PyInstaller failed! >> "%LOG_FILE%"
    pause
    exit /b 1
)

:: Check for created EXE
if not exist "%EXE_PATH%" (
    echo Error: .exe was not created!
    echo Error: .exe was not created! >> "%LOG_FILE%"
    pause
    exit /b 1
)

:: Control signing flow based on user choice
if /i "!SIGN_WITH_YUBIKEY!"=="true" (
    goto sign_exe
) else (
    echo Skipping YubiKey signing as per user choice.
    echo Skipping YubiKey signing as per user choice. >> "%LOG_FILE%"
    echo Note: If a YubiKey PIN prompt appears, it may be due to an external driver or auto-signing feature.
    echo Remove the YubiKey or disable auto-signing in YubiKey Manager before proceeding.
    echo Note: If a YubiKey PIN prompt appears... >> "%LOG_FILE%"
    timeout /t 5 >nul
    goto skip_signing
)

:sign_exe
echo.
echo =====================================================================
echo Signing EXE with YubiKey... (A prompt for your PIN will appear)
echo =====================================================================
echo.
echo Signing EXE with YubiKey... >> "%LOG_FILE%"

powershell -ExecutionPolicy Bypass -Command "$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1; if ($cert) { Set-AuthenticodeSignature -FilePath '%EXE_PATH%' -Certificate $cert -TimestampServer 'http://timestamp.digicert.com' } else { Write-Host 'No code signing certificate found in the current user store.'; exit 1 }" >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to sign EXE file with PowerShell!
    echo Error: Failed to sign EXE file with PowerShell! >> "%LOG_FILE%"
    echo Make sure YubiKey is connected and you entered the correct PIN.
    echo Make sure YubiKey is connected and you entered the correct PIN. >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo EXE file signed successfully.
echo EXE file signed successfully. >> "%LOG_FILE%"

:: Verify the signature
echo Verifying signature...
echo Verifying signature... >> "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -Command "if ((Get-AuthenticodeSignature -FilePath '%EXE_PATH%').Status -eq 'Valid') { Write-Host 'Signature verification: OK' } else { Write-Host 'Signature verification: FAILED'; exit 1 }" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Signature verification failed!
    echo Error: Signature verification failed! >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo Signature verified successfully.
echo Signature verified successfully. >> "%LOG_FILE%"

:skip_signing
:: Move the EXE to the script directory
echo Moving final EXE to project directory...
echo Moving final EXE to project directory... >> "%LOG_FILE%"
if exist "%FINAL_EXE_PATH%" del "%FINAL_EXE_PATH%"
move "%EXE_PATH%" "%FINAL_EXE_PATH%" >> "%LOG_FILE%" 2>&1

if not exist "%FINAL_EXE_PATH%" (
    echo Error: Failed to move .exe to final destination!
    echo Error: Failed to move .exe to final destination! >> "%LOG_FILE%"
    pause
    exit /b 1
)

:: Clean up
echo Cleaning up temporary files...
echo Cleaning up temporary files... >> "%LOG_FILE%"
call "%VENV_DIR%\Scripts\deactivate.bat"
rd /s /q "%TEMP_DIR%"

echo.
echo =====================================================================
echo Build successful!
echo File created at: %FINAL_EXE_PATH%
echo =====================================================================
echo.
pause