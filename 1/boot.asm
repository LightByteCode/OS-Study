;mbr启动并在屏幕上输出（将字符储存到对应的寄存器从而显示文死
mbrseg         equ    7c0h     ;启动扇区存放段地址

jmp   start
message:       db 'hello,OS world!','$'

start:
mov   ax,mbrseg
mov   ds,ax
mov   si,message
call  printstr
jmp   $

printstr:                  ;显示指定的字符串, 以'$'为结束标记
      mov al,[si]
      cmp al,'$'
      je disover
      mov ah,0eh
      int 10h
      inc si
      jmp printstr
disover:
      ret

times 510-($-$$) db 0
db 0x55,0xaa

times 1474560-($-$$) db 0