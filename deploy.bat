@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set VENV_DIR=%~dp0venv
set ERROR_LOG=%~dp0deploy_error.log
set REPORT_URL=http://localhost:8000/api/deploy/error
set TASK_ID=6

echo ========================================
echo   Deploy Pilot — 一键部署
echo ========================================
echo.

REM 初始化错误日志
echo 部署开始 — %DATE% %TIME% >"%ERROR_LOG%"

REM --- 0. 检测 Python ---
echo [0/4] 检测 Python...
set PYTHON_EXE=
where python >nul 2>&1 && set PYTHON_EXE=python && goto :found_python
where python3 >nul 2>&1 && set PYTHON_EXE=python3 && goto :found_python
for %%d in (
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "C:\Python312\python.exe" "C:\Python311\python.exe"
) do if exist %%d set PYTHON_EXE=%%d && goto :found_python
echo [ERROR_CODE:0] 未检测到 Python，请安装 https://python.org >>"%ERROR_LOG%"
goto :error

:found_python
echo   Python: %PYTHON_EXE%

REM --- 1. 创建虚拟环境 ---
echo [1/4] 创建虚拟环境...
if exist "%VENV_DIR%" (
    echo 虚拟环境已存在，跳过创建
) else (
    %PYTHON_EXE% -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR_CODE:1] 创建虚拟环境失败 >>"%ERROR_LOG%"
        goto :error
    )
)
call "%VENV_DIR%\Scripts\activate.bat"

REM --- 2. 安装依赖 ---
echo [2/4] 安装依赖...
if exist requirements.txt (
    pip install -r requirements.txt 2>>"%ERROR_LOG%"
    if errorlevel 1 (
        echo [ERROR_CODE:2] pip install 失败 >>"%ERROR_LOG%"
        goto :error
    )
) else (
    echo 无 requirements.txt，跳过
)

REM --- 3. 前置步骤 ---
echo [3/4] 执行前置步骤...
REM 无前置步骤

REM --- 4. 启动 ---
echo [4/4] 启动项目...
streamlit run {file}
if errorlevel 1 (
    echo [ERROR_CODE:4] 启动失败 >>"%ERROR_LOG%"
    goto :error
)

:end
echo.
echo ========================================
echo   部署完成！
echo ========================================
pause
exit /b 0

:error
echo.
echo ========================================
echo   部署失败！错误日志: %ERROR_LOG%
echo ========================================
echo 正在上报错误...
curl -s -X POST "%REPORT_URL%/upload" -F "log=@%ERROR_LOG%" -F "task_id=%TASK_ID%" >nul 2>&1
type "%ERROR_LOG%"
pause
exit /b 1
