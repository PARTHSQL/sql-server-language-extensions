@ECHO ON
SETLOCAL

ECHO [LOG] Script started.

REM Nuget packages directory and location of python libs
REM
SET ENL_ROOT=%~dp0..\..\..\..
ECHO [LOG] ENL_ROOT set to %ENL_ROOT%
SET PACKAGES_ROOT=%ENL_ROOT%\packages
ECHO [LOG] PACKAGES_ROOT set to %PACKAGES_ROOT%
SET PYTHONEXTENSION_HOME=%ENL_ROOT%\language-extensions\python
ECHO [LOG] PYTHONEXTENSION_HOME set to %PYTHONEXTENSION_HOME%
SET PYTHONEXTENSION_WORKING_DIR=%ENL_ROOT%\build-output\pythonextension\windows
ECHO [LOG] PYTHONEXTENSION_WORKING_DIR set to %PYTHONEXTENSION_WORKING_DIR%

IF EXIST %PYTHONEXTENSION_WORKING_DIR% (
	ECHO [LOG] Removing existing PYTHONEXTENSION_WORKING_DIR: %PYTHONEXTENSION_WORKING_DIR%
	RMDIR /s /q %PYTHONEXTENSION_WORKING_DIR%
)
ECHO [LOG] Creating PYTHONEXTENSION_WORKING_DIR: %PYTHONEXTENSION_WORKING_DIR%
MKDIR %PYTHONEXTENSION_WORKING_DIR%

SET BOOST_VERSION=1.79.0
ECHO [LOG] BOOST_VERSION set to %BOOST_VERSION%
SET BOOST_VERSION_IN_UNDERSCORE=1_79_0
ECHO [LOG] BOOST_VERSION_IN_UNDERSCORE set to %BOOST_VERSION_IN_UNDERSCORE%
SET DEFAULT_BOOST_ROOT=%PACKAGES_ROOT%\boost_%BOOST_VERSION_IN_UNDERSCORE%
ECHO [LOG] DEFAULT_BOOST_ROOT set to %DEFAULT_BOOST_ROOT%
SET DEFAULT_BOOST_PYTHON_ROOT=%DEFAULT_BOOST_ROOT%\stage\lib
ECHO [LOG] DEFAULT_BOOST_PYTHON_ROOT set to %DEFAULT_BOOST_PYTHON_ROOT%
SET DEFAULT_PYTHONHOME=C:\Python310
ECHO [LOG] DEFAULT_PYTHONHOME set to %DEFAULT_PYTHONHOME%
SET DEFAULT_CMAKE_ROOT=%PACKAGES_ROOT%\CMake-win64.3.15.5
ECHO [LOG] DEFAULT_CMAKE_ROOT set to %DEFAULT_CMAKE_ROOT%

REM Find boost, python, and cmake paths from user, or set to default for tests.
REM
SET ENVVAR_NOT_FOUND=203
ECHO [LOG] ENVVAR_NOT_FOUND set to %ENVVAR_NOT_FOUND%

IF "%BOOST_ROOT%" == "" (
	ECHO [LOG] BOOST_ROOT not defined.
	IF EXIST %DEFAULT_BOOST_ROOT% (
		ECHO [LOG] DEFAULT_BOOST_ROOT exists, setting BOOST_ROOT.
		SET BOOST_ROOT=%DEFAULT_BOOST_ROOT%
	) ELSE (
		ECHO [LOG] DEFAULT_BOOST_ROOT does not exist, calling :CHECKERROR.
		CALL :CHECKERROR %ENVVAR_NOT_FOUND% "Error: BOOST_ROOT variable must be set to build the python extension" || EXIT /b %ENVVAR_NOT_FOUND%
	)
) ELSE (
	ECHO [LOG] BOOST_ROOT already defined as %BOOST_ROOT%
)

IF "%BOOST_PYTHON_ROOT%" == "" (
	ECHO [LOG] BOOST_PYTHON_ROOT not defined.
	IF EXIST "%DEFAULT_BOOST_PYTHON_ROOT%" (
		ECHO [LOG] DEFAULT_BOOST_PYTHON_ROOT exists, setting BOOST_PYTHON_ROOT.
		SET BOOST_PYTHON_ROOT=%DEFAULT_BOOST_PYTHON_ROOT%
	) ELSE (
		ECHO [LOG] DEFAULT_BOOST_PYTHON_ROOT does not exist, calling :CHECKERROR.
		CALL :CHECKERROR %ENVVAR_NOT_FOUND% "Error: BOOST_PYTHON_ROOT variable must be set to build the python extension" || EXIT /b %ENVVAR_NOT_FOUND%
	)
) ELSE (
	ECHO [LOG] BOOST_PYTHON_ROOT already defined as %BOOST_PYTHON_ROOT%
)

IF "%PYTHONHOME%" == "" (
	ECHO [LOG] PYTHONHOME not defined.
	IF EXIST %DEFAULT_PYTHONHOME% (
		ECHO [LOG] DEFAULT_PYTHONHOME exists, setting PYTHONHOME.
		SET PYTHONHOME=%DEFAULT_PYTHONHOME%
	) ELSE (
		ECHO [LOG] DEFAULT_PYTHONHOME does not exist, calling :CHECKERROR.
		CALL :CHECKERROR %ENVVAR_NOT_FOUND% "Error: PYTHONHOME variable must be set to build the python extension" || EXIT /b %ENVVAR_NOT_FOUND%
	)
) ELSE (
	ECHO [LOG] PYTHONHOME already defined as %PYTHONHOME%
)

IF "%CMAKE_ROOT%" == "" (
	ECHO [LOG] CMAKE_ROOT not defined.
	IF EXIST %DEFAULT_CMAKE_ROOT% (
		ECHO [LOG] DEFAULT_CMAKE_ROOT exists, setting CMAKE_ROOT.
		SET CMAKE_ROOT=%DEFAULT_CMAKE_ROOT%
	) ELSE (
		ECHO [LOG] DEFAULT_CMAKE_ROOT does not exist, calling :CHECKERROR.
		CALL :CHECKERROR %ENVVAR_NOT_FOUND% "Error: CMAKE_ROOT variable must be set to build the python extension" || EXIT /b %ENVVAR_NOT_FOUND%
	)
) ELSE (
	ECHO [LOG] CMAKE_ROOT already defined as %CMAKE_ROOT%
)

:LOOP

REM Set cmake config to first arg
REM
SET CMAKE_CONFIGURATION=%1
ECHO [LOG] CMAKE_CONFIGURATION argument set to %CMAKE_CONFIGURATION%

REM *Setting CMAKE_CONFIGURATION to anything but "debug" will set CMAKE_CONFIGURATION to "release".
REM The string comparison for CMAKE_CONFIGURATION is case-insensitive.
REM
IF NOT DEFINED CMAKE_CONFIGURATION (
	ECHO [LOG] CMAKE_CONFIGURATION not defined, setting to release.
	SET CMAKE_CONFIGURATION=release
)
IF /I NOT %CMAKE_CONFIGURATION%==debug (
	ECHO [LOG] CMAKE_CONFIGURATION is not debug, setting to release.
	SET CMAKE_CONFIGURATION=release
)

REM Output directory and output dll name
REM
SET TARGET="%ENL_ROOT%\build-output\pythonextension\target\%CMAKE_CONFIGURATION%"
ECHO [LOG] TARGET set to %TARGET%

REM Remove existing output files
REM
IF EXIST %TARGET% (
	ECHO [LOG] Removing existing TARGET directory: %TARGET%
	RMDIR /s /q %TARGET%
)

REM Create the output directories
REM
ECHO [LOG] Creating TARGET directory: %TARGET%
mkdir %TARGET%

REM VSCMD_START_DIR set the working directory to this variable after calling VsDevCmd.bat
REM otherwise, it will default to %USERPROFILE%\Source
REM
SET VSCMD_START_DIR=%ENL_ROOT%
ECHO [LOG] VSCMD_START_DIR set to %VSCMD_START_DIR%

REM Do not call VsDevCmd if the environment is already set. Otherwise, it will keep appending
REM to the PATH environment variable and it will be too long for windows to handle.
REM
if not defined DevEnvDir (
	ECHO [LOG] DevEnvDir not defined, calling VsDevCmd.bat.
	call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat" -arch=amd64 -host_arch=amd64
) ELSE (
	ECHO [LOG] DevEnvDir already defined.
)

ECHO "[INFO] Generating Python extension s project build files using CMAKE_CONFIGURATION=%CMAKE_CONFIGURATION%"

SET BUILD_OUTPUT=%PYTHONEXTENSION_WORKING_DIR%\%CMAKE_CONFIGURATION%
ECHO [LOG] BUILD_OUTPUT set to %BUILD_OUTPUT%
ECHO [LOG] Creating BUILD_OUTPUT directory: %BUILD_OUTPUT%
MKDIR %BUILD_OUTPUT%
ECHO [LOG] Pushing directory to BUILD_OUTPUT: %BUILD_OUTPUT%
PUSHD %BUILD_OUTPUT%

ECHO "[INFO] CMAKE_ROOT=%CMAKE_ROOT% BOOST_ROOT=%BOOST_ROOT% BOOST_PYTHON_ROOT=%BOOST_PYTHON_ROOT% PYTHONHOME=%PYTHONHOME% CMAKE_CONFIGURATION=%CMAKE_CONFIGURATION%"
ECHO "[INFO] BUILD_OUTPUT=%BUILD_OUTPUT% TARGET=%TARGET%"


REM Call cmake
REM
ECHO [LOG] Calling cmake to generate build files.
CALL "%CMAKE_ROOT%\bin\cmake.exe" ^
	-G "Visual Studio 16 2019" ^
	-DPLATFORM=Windows ^
	-DENL_ROOT="%ENL_ROOT%" ^
	-DCMAKE_BUILD_TYPE=%CMAKE_CONFIGURATION% ^
	-DPYTHONHOME="%PYTHONHOME%" ^
	-DBOOST_ROOT="%BOOST_ROOT%" ^
	-DBOOST_PYTHON_ROOT="%BOOST_PYTHON_ROOT%" ^
	%PYTHONEXTENSION_HOME%/src

CALL :CHECKERROR %ERRORLEVEL% "Error: Failed to generate make files for CMAKE_CONFIGURATION=%CMAKE_CONFIGURATION%" || EXIT /b %ERRORLEVEL%

ECHO "[INFO] Building Python extension project using CMAKE_CONFIGURATION=%CMAKE_CONFIGURATION%"

REM Call cmake build
REM
ECHO [LOG] Calling cmake to build project.
CALL "%CMAKE_ROOT%\bin\cmake.exe" --build . --config %CMAKE_CONFIGURATION% --target INSTALL

CALL :CHECKERROR %ERRORLEVEL% "Error: Failed to build Python extension for CMAKE_CONFIGURATION=%CMAKE_CONFIGURATION%" || EXIT /b %ERRORLEVEL%

REM Copy DLL, LIB, etc files out of debug/debug and release/release into the build output folder
REM
ECHO [LOG] Copying build artifacts from %BUILD_OUTPUT%\%CMAKE_CONFIGURATION%\* to %BUILD_OUTPUT%\
copy %BUILD_OUTPUT%\%CMAKE_CONFIGURATION%\* %BUILD_OUTPUT%\

REM This will create the Python extension package with unsigned binaries, this is used for local development and non-release builds.
REM Release builds will call create-python-extension-zip.cmd after the binaries have been signed and this will be included in the zip
REM
IF /I %CMAKE_CONFIGURATION%==debug (
	ECHO [LOG] Creating zip archive with DLL and PDB for debug build.
	powershell -NoProfile -ExecutionPolicy Unrestricted -Command "Compress-Archive -Force -Path %BUILD_OUTPUT%\pythonextension.dll, %BUILD_OUTPUT%\pythonextension.pdb -DestinationPath %TARGET%\python-lang-extension.zip"
) ELSE (
	ECHO [LOG] Creating zip archive with DLL for release build.
	powershell -NoProfile -ExecutionPolicy Unrestricted -Command "Compress-Archive -Force -Path %BUILD_OUTPUT%\pythonextension.dll -DestinationPath %TARGET%\python-lang-extension.zip"
)

CALL :CHECKERROR %ERRORLEVEL% "Error: Failed to create zip for Python extension for CMAKE_CONFIGURATION=%CMAKE_CONFIGURATION%" || EXIT /b %ERRORLEVEL%

REM Advance arg passed to build-pythonextension.cmd
REM
ECHO [LOG] Shifting arguments.
SHIFT

REM Continue building using more configs until argv has been exhausted
REM
IF NOT "%~1"=="" (
	ECHO [LOG] Next argument found: %~1, looping.
	GOTO LOOP
) ELSE (
	ECHO [LOG] No more arguments, exiting loop.
)

ECHO [LOG] Script finished.
EXIT /b %ERRORLEVEL%

:CHECKERROR
	ECHO [LOG] Entered :CHECKERROR with error code %1 and message: %2
	IF %1 NEQ 0 (
		ECHO %2
		ECHO [LOG] Exiting with error code %1
		EXIT /b %1
	)
	ECHO [LOG] No error, continuing.
	EXIT /b 0
