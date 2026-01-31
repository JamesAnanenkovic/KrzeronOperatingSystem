; drivers/load_file.asm
bits 16

global load_file
extern print_string

BUFFER equ 0x8000

load_file:
    pusha
    push es             ; ES’i kaydet

    mov bx, BUFFER
    mov es, bx
    xor bx, bx

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x00
    int 0x13

    jc .fail

    mov si, ok_msg
    call print_string
    jmp .done

.fail:
    mov si, disk_err_msg
    call print_string

.done:
    pop es              ; ES’i geri yükle
    popa
    ret


ok_msg db 'Sector read OK',13,10,0
disk_err_msg db 'Disk read error',13,10,0
