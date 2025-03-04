@echo off
echo Setting up test environment...

REM Create directory structure
echo.
echo Creating directories...
mkdir "C:\blockchain" 2>nul
mkdir "C:\blockchain\helper" 2>nul
mkdir "C:\blockchain\logs" 2>nul
mkdir "C:\blockchain\config" 2>nul
echo [OK] Directories created

REM Create basic configuration
echo.
echo Creating configuration files...
echo # Basic configuration > "C:\blockchain\config.sh"
echo NETWORK=pulsechain >> "C:\blockchain\config.sh"
echo EXECUTION_CLIENT=geth >> "C:\blockchain\config.sh"
echo CONSENSUS_CLIENT=lighthouse >> "C:\blockchain\config.sh"
echo [OK] Configuration created

REM Create sample helper scripts
echo.
echo Creating helper scripts...
echo #!/bin/bash > "C:\blockchain\helper\health_check.sh"
echo #!/bin/bash > "C:\blockchain\helper\log_viewer.sh"
echo #!/bin/bash > "C:\blockchain\helper\sync_recovery.sh"
echo [OK] Helper scripts created

REM Create sample logs
echo.
echo Creating log files...
echo Sample execution log > "C:\blockchain\logs\execution.log"
echo Sample consensus log > "C:\blockchain\logs\consensus.log"
echo Sample health log > "C:\blockchain\logs\health_check.log"
echo [OK] Log files created

echo.
echo Test environment setup completed.
echo Running tests to verify setup... 