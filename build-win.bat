@echo off
color a
echo Build script for Windows
echo.

echo Assembling OS Kernel...
cd tools
start nasm2 -O0 -f bin -o %~d0\bin\bootload.bin %~d0\src\bootload.asm

echo Adding bootsector to disk image...
start partcopy %~d0\bin\bootload.bin %~d0\img\os2.flp 0d 511d
cd ..

echo Done!
