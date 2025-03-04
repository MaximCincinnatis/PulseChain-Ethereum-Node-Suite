@echo off
echo Testing environment setup...

REM Test Docker
echo.
echo Testing Docker...
docker --version
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker is installed
) else (
    echo [FAIL] Docker is not installed
)

REM Test Docker service
echo.
echo Testing Docker service...
sc query docker > nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker service exists
) else (
    echo [FAIL] Docker service not found
)

REM Test network connectivity
echo.
echo Testing network connectivity...
ping 8.8.8.8 -n 1 > nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Network is connected
) else (
    echo [FAIL] Network connection failed
)

REM Test directory structure
echo.
echo Testing directory structure...
if exist "C:\blockchain" (
    echo [OK] Main directory exists
) else (
    echo [FAIL] Main directory not found
)

if exist "C:\blockchain\helper" (
    echo [OK] Helper directory exists
) else (
    echo [FAIL] Helper directory not found
)

REM Test configuration
echo.
echo Testing configuration...
if exist "C:\blockchain\config.sh" (
    echo [OK] Configuration file exists
) else (
    echo [FAIL] Configuration file not found
)

echo.
echo Environment tests completed. 