@echo off
setlocal
rem Local Windows launcher. Install Gradle 8.14.1 and expose gradle.bat on PATH,
rem or set GRADLE_HOME to the Gradle installation directory.
if defined GRADLE_HOME (
  if exist "%GRADLE_HOME%\bin\gradle.bat" (
    call "%GRADLE_HOME%\bin\gradle.bat" -p "%~dp0" %*
    exit /b %ERRORLEVEL%
  )
)
where gradle >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  call gradle -p "%~dp0" %*
  exit /b %ERRORLEVEL%
)
echo Gradle 8.14.1 was not found. Set GRADLE_HOME or add Gradle to PATH.
exit /b 1
