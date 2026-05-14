@echo off
chcp 65001 >nul
echo ========================================
echo    TimePersona - One-Click Start
echo ========================================
echo.
echo Starting Docker services...
docker compose up -d --build
echo.
echo Waiting for services to be ready...
timeout /t 8 /nobreak >nul
echo.
echo ----------------------------------------
echo  Services started!
echo ----------------------------------------
echo  Web App:     http://localhost:8080
echo  API:         http://localhost:3030
echo  Health:      http://localhost:8080/health
echo ----------------------------------------
echo.
echo Press any key to open browser...
pause >nul
start http://localhost:8080
