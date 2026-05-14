@echo off
chcp 65001 >nul
echo ========================================
echo    TimePersona - Stop Services
echo ========================================
echo.
docker compose down
echo.
echo All services stopped.
pause
