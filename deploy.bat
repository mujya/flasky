@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: Deploy Pilot - 一键部署脚本
:: 任务 ID: 16
:: 查询码: 843AB5C6
:: ============================================

set "QUERY_CODE=843AB5C6"
set "TASK_ID=16"
set "ERROR_API=http://10.254.1.15:8000/api/deploy/error/upload"
set "LOG_FILE=%~dp0deploy_error.log"
set "STEP="



:end
:: ============================================
:: 部署成功
:: ============================================
echo [OK] Deploy complete!
echo Query code: %QUERY_CODE% (for error lookup only)
pause
exit /b 0

:: ============================================
:: 错误处理
:: ============================================
:error
echo [ERROR] Step "%STEP%" failed >> %LOG_FILE%
echo [ERROR] Deploy failed >> %LOG_FILE%
echo.
echo ========================================
echo  Deploy failed!
echo  Query code: %QUERY_CODE%
echo  Reporting error...
echo ========================================

powershell -Command ^
  "$log = ''; try { $log = Get-Content '%LOG_FILE%' -Raw } catch {}; ^
   $body = @{task_id=16;error_log=\"Query: %QUERY_CODE%`n$log\"} | ConvertTo-Json; ^
   try { Invoke-RestMethod -Uri '%ERROR_API%' -Method POST ^
     -Body $body -ContentType 'application/json' } catch {}"

echo.
echo Paste the query code %QUERY_CODE% in Deploy Pilot for auto-fix.
pause
exit /b 1
