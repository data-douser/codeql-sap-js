@echo off

if "%~1"=="" (
    echo Usage: %0 ^<response_file_path^>
    exit /b 1
)

where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo node executable is required (in PATH) to run the 'index-files.js' script. Please install Node.js and try again.
    exit /b 2
)

where npm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo npm executable is required (in PATH) to install the dependencies for the 'index-files.js' script.
    exit /b 3
)

set "_response_file_path=%~1"

echo Checking response file for CDS files to index

if not exist "%_response_file_path%" (
    echo 'codeql database index-files --language cds' command terminated early as response file '%_response_file_path%' does not exist or is empty. This is because no CDS files were selected or found.
    exit /b 0
)

echo Installing node package dependencies and running the 'index-files.js' script
npm install --quiet --no-audit --no-fund --no-package-json && ^
node "%~dp0index-files.js" "%_response_file_path%"

exit /b %ERRORLEVEL%