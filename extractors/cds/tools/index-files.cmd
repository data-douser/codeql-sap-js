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
set "_script_dir=%~dp0"

echo Checking response file for CDS files to index

if not exist "%_response_file_path%" (
    echo 'codeql database index-files --language cds' command terminated early as response file '%_response_file_path%' does not exist or is empty. This is because no CDS files were selected or found.
    exit /b 0
)

REM Change to the directory of this script to ensure that npm looks up
REM the package.json file in the correct directory and installs the
REM dependencies (i.e. node_modules) relative to this directory.
cd /d "%_script_dir%" && ^
echo Installing node package dependencies and running the 'index-files.js' script && ^
npm install --quiet --no-audit --no-fund --no-package-json && ^
node "%_script_dir%index-files.js" "%_response_file_path%"

exit /b %ERRORLEVEL%