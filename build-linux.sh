rm -f os2.flp
mkdosfs -C os2.flp 1440 || exit
nasm -f bin -o bootload.bin bootload.asm
dd status=noxfer conv=notrunc if=bootload.bin of=os2.flp
