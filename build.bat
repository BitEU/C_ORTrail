@echo off
REM Build script for BBC Baseball Simulation
REM Unified script for MSVC and MinGW compilation
REM Supports selecting between MLB and World Series 2024 player data

echo.
echo ========================================
echo   BBC Baseball - Unified Build Script
echo ========================================
echo.

set COMPILER=
set UNIVAC_BUILD=
set PLAYERS=

REM ============================================================================
REM STEP 1: SELECT PLATFORM
REM ============================================================================
set PLATFORM=
echo Please select target platform:
echo   Press ENTER or 1 for Windows
echo   Press 2 for UNIVAC (cross-compile)
echo.
set /p PLATFORM="Enter your choice (default: Windows): "

if "%PLATFORM%"=="" set PLATFORM=1
if "%PLATFORM%"=="1" goto SELECT_COMPILER
if "%PLATFORM%"=="2" (
    set COMPILER=1
    set UNIVAC_BUILD=1
    goto SELECT_PLAYERS
)
echo Invalid choice. Defaulting to Windows.
set PLATFORM=1

REM ============================================================================
REM STEP 2: SELECT COMPILER (Windows only)
REM ============================================================================
:SELECT_COMPILER
echo.
echo Please select your compiler:
echo   Press ENTER or 1 for MinGW
echo   Press 2 for MSVC
echo.
set /p COMPILER="Enter your choice (default: MinGW): "

if "%COMPILER%"=="" set COMPILER=1
if "%COMPILER%"=="1" goto SELECT_PLAYERS
if "%COMPILER%"=="2" goto SELECT_PLAYERS
echo Invalid choice. Defaulting to MinGW.
set COMPILER=1

REM ============================================================================
REM STEP 3: SELECT PLAYER DATA
REM ============================================================================
:SELECT_PLAYERS
echo.
echo Please select player data:
echo   Press ENTER or 1 for MLB League Players (players.c)
echo   Press 2 for World Series 2024 Players (World_Series_2024_players.c)
echo.
set /p PLAYERS="Enter your choice (default: MLB): "

if "%PLAYERS%"=="" set PLAYERS=1
if "%PLAYERS%"=="1" (
    set PLAYERS_FILE=players.c
    set PLAYERS_DESC=MLB League Players
    goto PLAYERS_SELECTED
)
if "%PLAYERS%"=="2" (
    set PLAYERS_FILE=World_Series_2024_players.c
    set PLAYERS_DESC=World Series 2024 Players
    goto PLAYERS_SELECTED
)
echo Invalid choice. Defaulting to MLB League Players.
set PLAYERS_FILE=players.c
set PLAYERS_DESC=MLB League Players

:PLAYERS_SELECTED
echo.
echo Selected: %PLAYERS_DESC%
echo.

REM Jump to the selected compiler build
if defined UNIVAC_BUILD goto UNIVAC_BUILD
if "%COMPILER%"=="1" goto MINGW_BUILD
if "%COMPILER%"=="2" goto MSVC_BUILD
goto MINGW_BUILD

REM ============================================================================
REM UNIVAC BUILD (Cross-compile with -DUNIVAC flag)
REM ============================================================================
:UNIVAC_BUILD
echo.
REM Check if gcc is available
where gcc >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: GCC not found in PATH
    echo Please install MinGW-w64 or your cross-compiler toolchain
    pause
    exit /b 1
)

echo Compiler: GCC with UNIVAC flag
gcc --version | findstr "gcc"
echo.

REM Clean previous build artifacts
echo Cleaning previous build artifacts...
if exist baseball_univac.exe del /Q baseball_univac.exe
if exist baseball_univac.o del /Q baseball_univac.o
if exist players_univac.o del /Q players_univac.o
if exist *.o del /Q *.o
echo.

echo Building for UNIVAC platform...
echo Compiler: GCC
echo Player Data: %PLAYERS_DESC%
echo Platform Flags: -DUNIVAC
echo.

echo Compiling baseball.c...
gcc -c -DUNIVAC -O2 -Wall baseball.c -o baseball_univac.o

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to compile baseball.c
    pause
    exit /b 1
)

echo Compiling %PLAYERS_FILE%...
gcc -c -DUNIVAC -O2 -Wall %PLAYERS_FILE% -o players_univac.o

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to compile %PLAYERS_FILE%
    pause
    exit /b 1
)

echo Linking...
gcc -o baseball_univac.exe baseball_univac.o players_univac.o

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   BUILD SUCCESSFUL - UNIVAC
    echo ========================================
    echo.
    echo Output: baseball_univac.exe

    REM Display file size
    for %%A in (baseball_univac.exe^) do (
        echo File size: %%~zA bytes
    )
    echo.
    echo Platform: UNIVAC ^(cross-compiled with -DUNIVAC^)
    echo.
    echo NOTE: This executable is built for UNIVAC compatibility:
    echo   - No Windows dependencies ^(windows.h, time.h^)
    echo   - No runtime roster initialization
    echo   - Uses strncpy instead of strcpy_s
    echo.
    goto :EOF
) else (
    echo.
    echo ========================================
    echo   BUILD FAILED
    echo ========================================
    echo.
    echo Check the error messages above.
    pause
    exit /b 1
)

exit /b 0

REM ============================================================================
REM MINGW BUILD
REM ============================================================================
:MINGW_BUILD
echo.
REM Check if gcc is available
where gcc >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: MinGW GCC not found in PATH
    echo Please install MinGW-w64 and add it to your PATH
    echo Download from: https://www.mingw-w64.org/
    pause
    exit /b 1
)

echo Compiler: MinGW GCC
gcc --version | findstr "gcc"
echo.

REM Clean previous build artifacts
echo Cleaning previous build artifacts...
if exist baseball_mingw.exe del /Q baseball_mingw.exe
if exist baseball.obj del /Q baseball.obj
if exist players.obj del /Q players.obj
if exist *.o del /Q *.o
echo.

REM ============================================================================
REM AGGRESSIVE OPTIMIZATION FLAGS
REM ============================================================================
REM -O3              : Maximum optimization level
REM -march=native    : Optimize for current CPU architecture
REM -mtune=native    : Tune code for current CPU
REM -flto            : Link-Time Optimization (whole program optimization)
REM -ffast-math      : Aggressive floating-point optimizations
REM -funroll-loops   : Unroll loops for better performance
REM -finline-functions : Inline functions aggressively
REM -fomit-frame-pointer : Remove frame pointer for faster function calls
REM -fno-stack-protector : Remove stack protection overhead
REM -fmerge-all-constants : Merge identical constants
REM -ftree-vectorize : Auto-vectorization of loops
REM -fprefetch-loop-arrays : Generate prefetch instructions
REM -msse4.2         : Use SSE 4.2 instructions
REM ============================================================================

set OPTIMIZE_FLAGS=-O3 -march=native -mtune=native -flto -ffast-math -funroll-loops -finline-functions -fomit-frame-pointer -fno-stack-protector -fmerge-all-constants -ftree-vectorize -fprefetch-loop-arrays -msse4.2

REM Warning flags (keep for code quality)
set WARNING_FLAGS=-Wall -Wextra -Wno-unused-parameter

REM Additional performance flags
set PERF_FLAGS=-DNDEBUG -pipe

REM Linker optimization flags
set LINKER_FLAGS=-s -static -Wl,--gc-sections -Wl,--strip-all -Wl,-O3

echo Building with aggressive optimizations...
echo Compiler: MinGW GCC
echo Player Data: %PLAYERS_DESC%
echo Flags: %OPTIMIZE_FLAGS%
echo.

echo Compiling and linking...
gcc %WARNING_FLAGS% %OPTIMIZE_FLAGS% %PERF_FLAGS% ^
    -o baseball_mingw.exe ^
    baseball.c %PLAYERS_FILE% ^
    %LINKER_FLAGS%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   BUILD SUCCESSFUL
    echo ========================================
    echo.
    echo Output: baseball_mingw.exe

    REM Display file size
    for %%A in (baseball_mingw.exe) do (
        echo File size: %%~zA bytes
    )
    echo.
    echo Optimization level: MAXIMUM (-O3 + LTO + native CPU^)
    echo.
    echo To run the game, type: baseball_mingw.exe
    echo.
) else (
    echo.
    echo ========================================
    echo   BUILD FAILED
    echo ========================================
    echo.
    echo Check the error messages above.
    pause
    exit /b 1
)

exit /b 0

REM ============================================================================
REM MSVC BUILD
REM ============================================================================
:MSVC_BUILD
echo.
REM Set up Visual Studio Developer Command Prompt environment
REM Try common Visual Studio 2022 installation paths
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -no_logo
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat" -no_logo
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" -no_logo
) else (
    echo Error: Could not find Visual Studio 2022 installation.
    echo Please ensure Visual Studio 2022 is installed.
    pause
    exit /b 1
)

echo.
echo Compiler: MSVC (Visual Studio 2022)
echo Player Data: %PLAYERS_DESC%
echo Compiling with MSVC...
echo.

REM Compile source files
cl /W4 /O2 /Fe:baseball.exe baseball.c %PLAYERS_FILE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   BUILD SUCCESSFUL
    echo ========================================
    echo.
    echo Output: baseball.exe
    echo.
    echo To run: baseball.exe
) else (
    echo.
    echo ========================================
    echo   BUILD FAILED
    echo ========================================
    echo.
    pause
    exit /b 1
)

exit /b 0
