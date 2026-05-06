@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set VENV_DIR=%~dp0venv
set ERROR_LOG=%~dp0deploy_error.log
set REPORT_URL=http://localhost:8000/api/deploy/error
set TASK_ID=12

echo ========================================
echo   Deploy Pilot
echo ========================================
echo.

REM Init log
echo Deploy started: %DATE% %TIME% >"%ERROR_LOG%"

REM --- 0. Find Python ---
echo [0/4] Locating Python...
set PYTHON_EXE=
where python >nul 2>&1 && set PYTHON_EXE=python && goto :found_python
where python3 >nul 2>&1 && set PYTHON_EXE=python3 && goto :found_python
echo [ERROR_CODE:0] Python not found. Install from https://python.org >>"%ERROR_LOG%"
goto :error

:found_python
echo   Python: %PYTHON_EXE%

REM Verify venv support
%PYTHON_EXE% -c "import venv" >nul 2>&1
if errorlevel 1 (
    echo [ERROR_CODE:0] Python at %PYTHON_EXE% missing venv module. Reinstall Python. >>"%ERROR_LOG%"
    goto :error
)

REM --- 1. Virtual env ---
echo [1/4] Creating virtual environment...
if exist "%VENV_DIR%" (
    echo   Already exists, skipping
) else (
    %PYTHON_EXE% -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR_CODE:1] Failed to create venv >>"%ERROR_LOG%"
        goto :error
    )
)
call "%VENV_DIR%\Scripts\activate.bat"

REM --- 2. Install deps ---
echo [2/4] Installing dependencies...
if exist requirements.txt (
    pip install -r requirements.txt 2>>"%ERROR_LOG%"
    if errorlevel 1 (
        echo [ERROR_CODE:2] pip install failed >>"%ERROR_LOG%"
        goto :error
    )
) else (
    echo   No requirements.txt, skipping
)

REM --- 3. Pre-steps ---
echo [3/4] Running pre-steps...
REM 无前置步骤

REM --- 4. Start ---
echo [4/4] Starting project...
streamlit run {file}
if errorlevel 1 (
    echo [ERROR_CODE:4] Start failed >>"%ERROR_LOG%"
    goto :error
)

:end
echo.
echo ========================================
echo   Deploy complete!
echo ========================================
pause
exit /b 0

:error
echo.
echo ========================================
echo   Deploy failed!  Log: %ERROR_LOG%
echo ========================================
echo Reporting error...
curl -s -X POST "%REPORT_URL%/upload" -F "log=@%ERROR_LOG%" -F "task_id=%TASK_ID%" >nul 2>&1
type "%ERROR_LOG%"
pause
exit /b 1
