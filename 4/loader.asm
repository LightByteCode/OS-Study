NUMsector      EQU    18       ; 最大扇区编号
NUMheader      EQU    1        ; 最大磁头编号
NUMcylind      EQU    5        ; 设置读取到的柱面编号

mbrseg         equ    7c0h     ; 启动扇区存放段地址
loaderseg      equ    800h     ; 从软盘读取LOADER到内存的段地址
kernalseg      equ    0c20h    ; 内核段地址 

jmp    short start             ; 为了制作PBP,第3个字节必须是 0x90。这里采用jmp short来占2字节 

        DB        0x90
        DB        "Light OS"        ; 启动区的名称可以是任意字符串(8字节)
        DW        512                ; 每个扇区(sector)的大小必须为512字节
        DB        1                ; 簇(cluster)的大小必须为1个扇区
        DW        1                ; FAT的起始位置(一般从第一个扇区开始)
        DB        2                ; FAT的个数(必须为2)
        DW        224                ; 根目录的大小(一般设为244项)
        DW        2880            ; 该磁盘的的大小(必须为2880扇区)
        DB        0xf0            ; 磁盘的种类(必须为0xfd)
        DW        9                ; FAT的长度(必须为9扇区)
        DW        18                ; 一个磁道(track)有几个扇区(必须为18)
        DW        2                ; 磁头数(必须为2)
        DD        0                ; 不使用分区(必须为0)
        DD        2880            ; 重写一次磁盘大小
        DB        0,0,0x29        ; 意义不明，固定
        DD        0xffffffff        ; (可能是)卷标号码
        DB        "LightByteOS"    ; 磁盘名称(11字节)
        DB        "FAT12   "        ; 磁盘格式名称(8字节)
        RESB    18               ; 先腾出18字节



start:

call showwelcome    ;初始化寄存器，打印必要信息 
call loader         ;执行loader,把现在这张软盘的数据全部读到8000h开始。 
jmp  kernalseg:0    ;跳转到内核。物理地址为c200h=8000h+4200h；8000为loader的
;开始地址,4200为kernal在FAT文件中的偏移地址
;注意jmp指令的操作后果,该跳转之后,CS=kernalseg=0c20h,IP=0,DS,ES保持不变。 

showwelcome: 
     mov   ax,mbrseg 
     mov   ds,ax   ;为显示各种提示信息做准备 
     mov   ax,loaderseg 
     mov   es,ax   ;为读软盘数据到内存做准备，因为读软盘需地址控制---ES:BX
     
     mov   si,welcome
     call  printstr
     call  newline
     ret

loader:
     mov   si, fyread
     call  printstr
     call  newline
     call  folppyload    ;将软盘的数据全部load到内存，从物理地址8000h开始 
     mov   si, Fycontent
     call  printstr
     call  showdata      ;可以验证一下从软盘读入的kernal程序数据是否正确(二进制) 
     ret



folppyload:                       
     call    read1sector
     MOV     AX,ES
     ADD     AX,0x0020
     MOV     ES,AX                ;一个扇区占512B=200H，刚好能被整除成完整的段,因此只需改变ES值，无需改变BP即可。 
     inc   byte [sector+11]
     cmp   byte [sector+11],NUMsector+1
     jne   folppyload             ;读完一个扇区
     mov   byte [sector+11],1
     inc   byte [header+11]
     cmp   byte [header+11],NUMheader+1
     jne   folppyload             ;读完一个磁头
     mov   byte [header+11],0
     inc   byte [cylind+11]
     cmp   byte [cylind+11],NUMcylind+1
     jne   folppyload             ;读完一个柱面

     ret
     
     
numtoascii:     ;将2位数的10进制数分解成ASII码才能正常显示。如柱面56 分解成出口ascii: al:35,ah:36
     mov ax,0
     mov al,cl  ;输入cl
     mov bl,10
     div bl
     add ax,3030h
     ret

readinfo:       ;显示当前读到哪个扇区、哪个磁头、哪个柱面 
     mov si,cylind
     call  printstr
     mov si,header
     call  printstr
     mov si,sector
     call  printstr
     ret


 
read1sector:                      ;读取一个扇区的通用程序。扇区参数由 sector header  cylind控制

       mov   cl, [sector+11]      ;为了能实时显示读到的物理位置
       call  numtoascii
       mov   [sector+7],al
       mov   [sector+8],ah

       mov   cl,[header+11]
       call  numtoascii
       mov   [header+7],al
       mov   [header+8],ah

       mov   cl,[cylind+11]
       call  numtoascii
       mov   [cylind+7],al
       mov   [cylind+8],ah

       MOV        CH,[cylind+11]    ; 柱面从0开始读
       MOV        DH,[header+11]    ; 磁头从0开始读
       mov        cl,[sector+11]    ; 扇区从1开始读        

        call       readinfo        ;显示软盘读到的物理位置
        mov        di,0
retry:
        MOV        AH,02H            ; AH=0x02 : AH设置为0x02表示读取磁盘
        MOV        AL,1            ; 要读取的扇区数
        mov        BX,    0         ; ES:BX表示读到内存的地址 0x0800*16 + 0 = 0x8000
        MOV        DL,00H           ; 驱动器号，0表示第一个软盘，是的，软盘。。硬盘C:80H C 硬盘D:81H
        INT        13H               ; 调用BIOS 13号中断，磁盘相关功能
        JNC        READOK           ; 未出错则跳转到READOK，出错的话则会使EFLAGS寄存器的CF位置1
           inc     di
           MOV     AH,0x00
           MOV     DL,0x00         ; A驱动器
           INT     0x13            ; 重置驱动器
           cmp     di, 5           ; 软盘很脆弱，同一扇区如果重读5次都失败就放弃 
           jne     retry

           mov     si, Fyerror
           call    printstr
           call    newline
           jmp     exitread
READOK:    mov     si, FloppyOK
           call    printstr
           call    newline
exitread:
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

showdata:  mov  si,0             ;验证显示从软盘读取到内存的数据 
           mov  ax, kernalseg 
           mov  es,ax
           mov  cx,9             ;控制输出的数据长度 
nextchar:  mov al,[es:si]
           mov ah,0eh
           int 10h
           inc si
           loop nextchar
           RET

welcome db 'Welcome Jiang OS!','$'
fyread  db 'Now Floppy Read Loader:','$'
cylind  db 'cylind:?? $',0    ; 设置开始读取的柱面编号
header  db 'header:?? $',0    ; 设置开始读取的磁头编号
sector  db 'sector:?? $',1    ; 设置开始读取的扇区编号
FloppyOK db '---Floppy Read OK','$'
Fyerror db '---Floppy Read Error' ,'$'
Fycontent db 'Floppy Content is:' ,'$'


times 510-($-$$) db 0
                 db 0x55,0xaa