;功能：跳出mbr扇区
mbrseg         equ    7c0h     ;启动扇区存放段地址
outseg         equ    800h     ;跳出MBR之后的段地址

jmp   start
megwelcome:     db '------Welcome OS------','$'
message1:       db 'step1:now is in mbr','$'
message2:       db 'step2:now jump out mbr','$'
message3:       db 'memory address is---','$'
message4:       db 'CS:????','$'

start:
mov   ax,mbrseg
mov   ds,ax
call  welcome
call  newline
call  newline
call  inmbr
call  showcs
call  newline
call  newline

jmp   outseg:0        ;通过此条指令跳出MBR区

call  outmbr
call  showcs


welcome:
mov   si,megwelcome
call  printstr
ret


inmbr:
mov   si,message1
call  printstr
call  newline
mov   si,message3
call  printstr
ret

outmbr:
mov   si,message2
call  printstr
call  newline
mov   si,message3
call  printstr
ret

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

newline:                     ;显示回车换行
      mov ah,0eh
      mov al,0dh
      int 10h
      mov al,0ah
      int 10h
      ret


showcs:                       ;展示CS的值
      mov  ax,cs

      mov  dl,ah
      call HL4BIT
      mov  dl,  BH
      call  ASCII
      mov  [message4+3],dl

      mov  dl,  Bl
      call  ASCII
      mov  [message4+4],dl

      mov  dl,al
      call HL4BIT
      mov  dl,  BH
      call  ASCII
      mov  [message4+5],dl

      mov  dl,  Bl
      call  ASCII
      mov  [message4+6],dl

      mov  si,  message4
      call printstr

      ret

;-----------------将16进制数字(1位)转换成ASCII码，输入DL,输出DL------
ASCII:   CMP  DL,9
         JG   LETTER  ;DL>OAH
         ADD  DL,30H  ;如果是数字,加30H即转换成ASCII码
         RET
LETTER:  ADD  DL,37H  ;如果是A～F,加37H即转换成ASCII码
         RET

;-----------------取出1个字节Byte的高4位和低4位,输入DL,输出BH和BL----------

HL4BIT:  MOV  DH,dl
         MOV  BL,dl
         SHR  DH,1
         SHR  DH,1
         SHR  DH,1
         SHR  DH,1
         MOV  BH,DH                    ;取高4位
         AND  BL,0FH                   ;取低4位
         RET


times 510-($-$$) db 0
db 0x55,0xaa