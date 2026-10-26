@echo off

cd /d "%~dp0"


rem assemble
as --64 "fixed_normal_calculation.asm" -o "fixed_normal_calculation.o"

if errorlevel 1 (
    echo assembler failed!
    pause
    exit /b 1
)

rem extract binary
objcopy -O binary -j .text "fixed_normal_calculation.o" "fixed_normal_calculation.bin"

if errorlevel 1 (
    echo extracting binary failed!
    pause
    exit /b 1
)

rem remove intermediate file
del "fixed_normal_calculation.o"


echo.
echo built payload succesfully!
pause