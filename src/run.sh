../bin/parser $1
nasm -f elf32 gen_code.asm 
gcc -m32 gen_code.o
