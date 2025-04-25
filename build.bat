@echo off
setlocal EnableDelayedExpansion

:: =====================================================================
:: CONFIGURATION - Change these parameters as needed
:: =====================================================================
:: OUTPUT_NAME will be set dynamically as the folder name
set "USE_NOCONSOLE=false"                     :: Change to true to hide console
set "GENERATE_CERTIFICATE=true"              :: Generate self-signed certificate?
set "CERT_COMPANY=Gamepadla"                 :: Company name for certificate
set "CERT_EMAIL=john@gamepadla.com"          :: Email for certificate (no escaping here)
set "CERT_PASSWORD=password123"              :: Certificate password
set "SIGN_EXE=true"                          :: Sign the EXE file?
set "REQUIRED_PACKAGES=pygame numpy requests colorama pillow" :: Required Python packages
set "USE_PYARMOR=false"                      :: Use PyArmor for code obfuscation?
set "PYARMOR_OPTIONS="                       :: PyArmor options (empty for free version)
:: =====================================================================

:: Set CMD encoding to UTF-8
chcp 65001 >nul

:: Script for creating a clean virtual environment, installing only necessary modules
:: and packaging Python.py into .exe using PyInstaller on Windows.

:: Clean up old temporary directories
echo Cleaning up old temporary directories...
for /d %%D in ("%TEMP%\%OUTPUT_NAME%Build_*") do rd /s /q "%%D" 2>nul

:: Path variables setup
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Extract the folder name from SCRIPT_DIR to set OUTPUT_NAME
for %%F in ("%SCRIPT_DIR%") do set "OUTPUT_NAME=%%~nxF"
echo Using OUTPUT_NAME: %OUTPUT_NAME%

:: Set CERT_NAME based on OUTPUT_NAME
set "CERT_NAME=%OUTPUT_NAME%Cert"
echo Using CERT_NAME: %CERT_NAME%

set "PYTHON_SCRIPT=%SCRIPT_DIR%\Python.py"
set "ICON_PNG_PATH=%SCRIPT_DIR%\icon.png"
set "ICON_ICO_PATH=%SCRIPT_DIR%\icon.ico"
set "UPX_DIR="
set "TEMP_DIR=%TEMP%\%OUTPUT_NAME%Build_%RANDOM%"
set "CERT_PATH=%TEMP_DIR%\%CERT_NAME%.pfx"
set "EXE_PATH=%TEMP_DIR%\dist\%OUTPUT_NAME%.exe"
set "FINAL_EXE_PATH=%SCRIPT_DIR%\%OUTPUT_NAME%.exe"
set "OBFUSCATED_DIR=%TEMP_DIR%\obfuscated"
set "OBFUSCATED_SCRIPT=%OBFUSCATED_DIR%\Python.py"

:: Check if Python.py exists
echo Checking for %PYTHON_SCRIPT%...
if not exist "%PYTHON_SCRIPT%" (
    echo Error: File %PYTHON_SCRIPT% not found!
    pause
    exit /b 1
)

:: Universal Python search
set "PYTHON="
echo Looking for Python...
:: Try 1: Look for py (Python Launcher)
where py >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PYTHON=py"
    echo Found py: Python Launcher
    goto :python_found
)

:: Try 2: Look for python
where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PYTHON=python"
    echo Found python
    goto :python_found
)

:: Try 3: Explicit Python path
set "PYTHON=C:\Users\cakam\AppData\Local\Programs\Python\Python313\python.exe"
if exist "!PYTHON!" (
    echo Found Python at path: !PYTHON!
    goto :python_found
)

:: If Python is not found
echo Error: Python not found! Make sure Python is installed and added to PATH.
echo Try 'py --version' or 'python --version' in command prompt.
pause
exit /b 1

:python_found
:: Check Python version
echo Checking Python version...
%PYTHON% --version
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to verify Python version!
    pause
    exit /b 1
)

:: Create temporary directory using OUTPUT_NAME
echo Creating temporary directory: %TEMP_DIR%...
mkdir "%TEMP_DIR%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create temporary directory %TEMP_DIR%!
    pause
    exit /b 1
)
set "VENV_DIR=%TEMP_DIR%\venv"

echo Creating virtual environment in %VENV_DIR%...

:: Create virtual environment
%PYTHON% -m venv "%VENV_DIR%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create virtual environment!
    pause
    exit /b 1
)

:: Activate virtual environment
echo Activating virtual environment...
call "%VENV_DIR%\Scripts\activate.bat"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to activate virtual environment!
    pause
    exit /b 1
)

:: Check if virtual environment was activated (check for pip)
echo Checking for pip...
where pip >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: pip not found after activating virtual environment!
    pause
    exit /b 1
)

:: Force update pip in virtual environment
echo Updating pip...
"%VENV_DIR%\Scripts\python.exe" -m pip install --upgrade pip
if %ERRORLEVEL% neq 0 (
    echo Warning: Failed to update pip, but will continue with current version...
)

echo Pip update check completed.
timeout /t 3 > nul

:: Install required packages
echo Required packages: %REQUIRED_PACKAGES%
echo Installing packages: %REQUIRED_PACKAGES%
pip install %REQUIRED_PACKAGES%
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to install packages!
    pause
    exit /b 1
)

:: Install PyInstaller
echo Installing PyInstaller...
pip install pyinstaller
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to install PyInstaller!
    pause
    exit /b 1
)

:: Install PyArmor for code obfuscation
if "%USE_PYARMOR%"=="true" (
    echo Installing PyArmor for code obfuscation...
    pip install pyarmor
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install PyArmor!
        echo Continuing without obfuscation...
        set "USE_PYARMOR=false"
    )
)

:: Convert PNG to ICO if icon.png exists and icon.ico does not
if exist "%ICON_PNG_PATH%" (
    if not exist "%ICON_ICO_PATH%" (
        echo Converting icon.png to icon.ico...
        :: Create a temporary Python script for conversion
        set "CONVERT_SCRIPT=%TEMP_DIR%\convert_png_to_ico.py"
        echo from PIL import Image > "%CONVERT_SCRIPT%"
        echo img = Image.open('%ICON_PNG_PATH%') >> "%CONVERT_SCRIPT%"
        echo img.save('%ICON_ICO_PATH%', 'ICO') >> "%CONVERT_SCRIPT%"
        :: Run the conversion
        "%VENV_DIR%\Scripts\python.exe" "%CONVERT_SCRIPT%"
        if %ERRORLEVEL% neq 0 (
            echo Warning: Failed to convert icon.png to icon.ico. Using PNG directly.
        ) else (
            echo Successfully converted icon.png to icon.ico.
        )
    ) else (
        echo icon.ico already exists, skipping conversion.
    )
)

:: Ensure the output EXE is not locked
echo Ensuring %FINAL_EXE_PATH% is not in use...
taskkill /F /IM "%OUTPUT_NAME%.exe" 2>nul
taskkill /F /IM explorer.exe 2>nul
start explorer.exe
timeout /t 5 /nobreak > nul

:: Attempt to delete the existing EXE file if it exists
if exist "%FINAL_EXE_PATH%" (
    echo Attempting to delete existing %FINAL_EXE_PATH%...
    del "%FINAL_EXE_PATH%"
    if exist "%FINAL_EXE_PATH%" (
        echo Warning: Could not delete %FINAL_EXE_PATH%. It may be in use by another process.
        echo Please ensure no processes are using the file and try again.
        pause
        exit /b 1
    )
)

:: Prepare PyArmor if enabled
if "%USE_PYARMOR%"=="true" (
    echo Obfuscating code with PyArmor...
    mkdir "%OBFUSCATED_DIR%" 2>nul
    
    :: Run PyArmor to obfuscate the main script
    echo Running: pyarmor gen --output "%OBFUSCATED_DIR%" "%PYTHON_SCRIPT%"
    pyarmor gen --output "%OBFUSCATED_DIR%" "%PYTHON_SCRIPT%" > "%TEMP_DIR%\pyarmor_obfuscation.log" 2>&1
    
    if %ERRORLEVEL% neq 0 (
        echo Error: PyArmor obfuscation failed! Check %TEMP_DIR%\pyarmor_obfuscation.log
        echo Continuing without obfuscation...
        set "USE_PYARMOR=false"
    ) else (
        echo Code obfuscation completed successfully.
        
        :: Obfuscate additional .py files
        echo Obfuscating additional .py files...
        for %%F in ("%SCRIPT_DIR%\*.py") do (
            if not "%%~nxF"=="Python.py" (
                echo Obfuscating: %%~nxF
                pyarmor gen --output "%OBFUSCATED_DIR%" "%%F" >> "%TEMP_DIR%\pyarmor_obfuscation.log" 2>&1
                if %ERRORLEVEL% neq 0 (
                    echo Warning: Failed to obfuscate %%~nxF, continuing...
                )
            )
        )
        
        :: Check if the obfuscated main script exists
        if exist "%OBFUSCATED_SCRIPT%" (
            echo Using obfuscated script: %OBFUSCATED_SCRIPT%
            set "PYTHON_SCRIPT=%OBFUSCATED_SCRIPT%"
            
            :: Verify PyArmor runtime
            if exist "%OBFUSCATED_DIR%\pyarmor_runtime_000000\__init__.py" (
                echo PyArmor runtime files successfully created.
            ) else (
                echo Error: PyArmor runtime files missing!
                set "USE_PYARMOR=false"
            )
            
            :: Log size of obfuscated script
            echo Checking size of obfuscated Python.py...
            dir "%OBFUSCATED_SCRIPT%"
            
            :: Copy resource files to obfuscated directory
            echo Copying resource files to obfuscated directory...
            for %%E in (png jpg gif wav mp3 csv json xml txt) do (
                for %%F in ("%SCRIPT_DIR%\*.%%E") do (
                    echo Copying resource: %%~nxF
                    copy "%%F" "%OBFUSCATED_DIR%\" >nul
                )
            )
        ) else (
            echo Warning: Obfuscated script not found, using original script: %PYTHON_SCRIPT%
        )
    )
)

:: Form PyInstaller command with hidden imports from REQUIRED_PACKAGES
set "PYINSTALLER_CMD=pyinstaller --clean --onefile --log-level DEBUG"
if "%USE_NOCONSOLE%"=="true" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --noconsole"
) else (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --console"
)
if exist "%ICON_ICO_PATH%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --icon="%ICON_ICO_PATH%""
) else if exist "%ICON_PNG_PATH%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --icon="%ICON_PNG_PATH%""
)
if exist "%ICON_PNG_PATH%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --add-data="%ICON_PNG_PATH%;.""
)
if not "%UPX_DIR%"=="" if exist "%UPX_DIR%" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --upx-dir="%UPX_DIR%""
)
:: Add hidden imports dynamically from REQUIRED_PACKAGES
for %%P in (%REQUIRED_PACKAGES%) do (
    set "PYINSTALLER_CMD=!PYINSTALLER_CMD! --hidden-import=%%P"
)
:: Ensure PyArmor runtime is included
if "%USE_PYARMOR%"=="true" (
    set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --hidden-import=pyarmor_runtime_000000"
)
set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --workpath="%TEMP_DIR%\build""
set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --distpath="%TEMP_DIR%\dist""
set "PYINSTALLER_CMD=%PYINSTALLER_CMD% --specpath="%TEMP_DIR%""
set "PYINSTALLER_CMD=%PYINSTALLER_CMD% -n "%OUTPUT_NAME%" "%PYTHON_SCRIPT%""

:: Execute PyInstaller
echo Running PyInstaller command...
echo Command: %PYINSTALLER_CMD%
%PYINSTALLER_CMD% > "%TEMP_DIR%\pyinstaller.log" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: PyInstaller failed! Check %TEMP_DIR%\pyinstaller.log for details.
    pause
    exit /b 1
)

:: Wait for PyInstaller to fully release the file
echo Waiting for file to be released at %EXE_PATH%...
set "RETRY_COUNT=0"
set "MAX_RETRIES=10"
:check_exe
timeout /t 5 /nobreak > nul
if exist "%EXE_PATH%" (
    echo Found %EXE_PATH%
    dir "%EXE_PATH%"
) else (
    set /a RETRY_COUNT+=1
    if !RETRY_COUNT! lss !MAX_RETRIES! (
        echo Attempt !RETRY_COUNT! of !MAX_RETRIES!: .exe not yet created, retrying...
        echo Current contents of %TEMP_DIR%\dist:
        dir "%TEMP_DIR%\dist" 2>nul
        goto :check_exe
    ) else (
        echo Error: .exe was not created after !MAX_RETRIES! attempts!
        echo Final contents of %TEMP_DIR%\dist:
        dir "%TEMP_DIR%\dist" 2>nul
        echo Check %TEMP_DIR%\pyinstaller.log for PyInstaller output.
        pause
        exit /b 1
    )
)

:: Self-signed certificate generation if needed
if "%GENERATE_CERTIFICATE%"=="true" (
    echo Generating self-signed certificate...
    
    :: Check for PowerShell
    where powershell >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo Error: PowerShell not found, skipping certificate generation.
    ) else (
        :: Remove existing certificate file if it exists
        if exist "%CERT_PATH%" (
            echo Removing existing certificate file: %CERT_PATH%...
            del "%CERT_PATH%"
        )

        :: Remove old certificates from the store
        echo Removing old certificates from store for %CERT_COMPANY%...
        powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like '*%CERT_COMPANY%*' -or $_.Subject -like '*GamepadLa*' } | ForEach-Object { Remove-Item -Path ('Cert:\CurrentUser\My\' + $_.Thumbprint) -Force; Write-Host ('Removed certificate: ' + $_.Thumbprint) }"

        :: Create new certificate
        echo Creating certificate %CERT_PATH%...
        powershell -ExecutionPolicy Bypass -Command "New-SelfSignedCertificate -Subject 'CN=%CERT_COMPANY%' -TextExtension '2.5.29.17={text}email=%CERT_EMAIL:@^=^@%' -CertStoreLocation 'Cert:\CurrentUser\My' -Type CodeSigningCert -KeyUsage DigitalSignature -KeySpec Signature | ForEach-Object { $pwd = ConvertTo-SecureString -String '%CERT_PASSWORD%' -Force -AsPlainText; Export-PfxCertificate -Cert ('Cert:\CurrentUser\My\' + $_.Thumbprint) -FilePath '%CERT_PATH%' -Password $pwd; Write-Host 'Certificate created.' }"

        if exist "%CERT_PATH%" (
            echo Certificate successfully created.
        ) else (
            echo Failed to create certificate. Skipping signing.
            goto :skip_signing
        )
        
        :: Try to close any processes that might be holding the file
        echo Ensuring file is not in use...
        taskkill /F /IM explorer.exe 2>nul
        start explorer.exe
        
        :: Wait a bit more
        timeout /t 5 /nobreak > nul
        
        :: Sign EXE file if certificate exists
        if "%SIGN_EXE%"=="true" (
            if exist "%CERT_PATH%" (
                echo Signing EXE file with certificate...
                
                :: Sign using direct PowerShell command - improved with retries
                powershell -ExecutionPolicy Bypass -Command "$maxRetries = 3; $retryCount = 0; $success = $false; while (-not $success -and $retryCount -lt $maxRetries) { try { $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq 'CN=%CERT_COMPANY%' } | Select-Object -First 1; if ($cert) { Set-AuthenticodeSignature -FilePath '%EXE_PATH%' -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'; Write-Host 'EXE file signed successfully.'; $success = $true; } else { Write-Host 'Certificate not found in certificate store.'; $success = $true; } } catch { Write-Host ('Attempt ' + ($retryCount+1) + ' failed: ' + $_.Exception.Message); $retryCount++; if ($retryCount -lt $maxRetries) { Start-Sleep -Seconds 5 } } }"
                
                :: Verify if signing was successful
                powershell -ExecutionPolicy Bypass -Command "if (Get-AuthenticodeSignature -FilePath '%EXE_PATH%' | Where-Object {$_.Status -ne 'NotSigned'}) { Write-Host 'Signature verification: EXE is signed.' } else { Write-Host 'Signature verification: EXE is NOT signed.' }"
            ) else (
                echo Certificate not found, skipping EXE signing.
            )
        )
    )
)

:skip_signing
:: Move the EXE to the script directory
echo Moving %EXE_PATH% to %FINAL_EXE_PATH%...
move "%EXE_PATH%" "%FINAL_EXE_PATH%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to move .exe to %FINAL_EXE_PATH%!
    pause
    exit /b 1
)

:: Check if the EXE was moved successfully
if not exist "%FINAL_EXE_PATH%" (
    echo Error: .exe was not moved to %FINAL_EXE_PATH%!
    pause
    exit /b 1
)

echo Compilation successful! File created: %FINAL_EXE_PATH%
dir "%FINAL_EXE_PATH%"

:: Deactivate and remove virtual environment
echo Deactivating virtual environment...
call "%VENV_DIR%\Scripts\deactivate.bat"

:: Remove temporary files
echo Removing temporary files...
rd /s /q "%TEMP_DIR%"

echo Done!
pause