@echo off

cd /d "%~dp0"


rem assemble
as --64 fixed_normal_calculation.asm -o fixed_normal_calculation.o

rem link calls
ld -m i386pep -Ttext=0x140000000 -e normal_hook_a1 -o fixed_normal_calculation.exe fixed_normal_calculation.o

rem print symbols
echo file symbols:
nm -n fixed_normal_calculation.exe

rem extract binary
objcopy -O binary -j .text fixed_normal_calculation.o fixed_normal_calculation.bin

rem remove intermediate files
del fixed_normal_calculation.o fixed_normal_calculation.exe


echo.
echo built payload succesfully!
pause