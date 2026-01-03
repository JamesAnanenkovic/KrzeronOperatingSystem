; Kr0nos Bootloader - NASM 16-bit uyumlu, 64-bit placeholder
bits 16
org 0x7C00

; - - - Ayarlamalar - - -
STACK_TOP      equ 0x9000
KERNEL_OFFSET  equ 0x1000
SECTORS        equ 8       ; okunacak sektör miktarı (512B * SECTORS)

start:
    ; Segment ve stack ayarları
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	xor sp, sp
	sti
    

    ; Boot sürücüsünü kaydet
    mov [boot_drive], dl

    ; Ekranı temizle
    mov ax, 0x0003
    int 0x10

    ; Hoşgeldin mesajı
    mov si, welcome_msg
    call print_string

    ; Kernel yükleme mesajı
    mov si, load_msg
    call print_string

    ; Kernel yükleme
    mov bx, 0x0000
    mov ax, KERNEL_OFFSET
    mov es, ax
    mov ah, 0x02        ; BIOS read sectors
    mov al, SECTORS
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2 (1-based)
    mov dh, 0           ; Head 0
    mov dl, byte [boot_drive]

    int 0x13
    jc disk_error       ; Hata varsa disk_error'a atla
    cmp al, 0
    je disk_error

    ; Kernel yükleme başarılı mesajı
    mov si, load_success_msg
    call print_string

    ; 64-bit geçiş placeholder
    mov si, pm_msg
    call print_string
    ; Uzun vadede buraya long mode setup gelecek:
    ; lgdt/gdt, enable A20, cr0 pe bit, jmp 64-bit kernel
    ; Şimdilik direkt jump
    jmp KERNEL_OFFSET:0x0000

; - - - Metin Yazdırma - - - (null-terminated)
print_string:
    pusha
    mov ah, 0x0E
    xor bx, bx

.print_loop:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_loop

.done:
    popa
    ret

; Hex yazdır
print_hex_digit:
    pusha
    and al, 0x0F
    cmp al, 10
    jl .is_digit
    add al, 7
.is_digit:
    add al, '0'
    mov ah, 0x0E
    int 0x10
    popa
    ret

; Disk hatası
disk_error:
    mov si, disk_error_msg
    call print_string
    mov cx, 3           ; retry sayısı

.retry:
    loop .retry
    cli
    hlt
    jmp $

; - - - DATA - - -
welcome_msg      db 'Krzeron OS Booting...', 0x0D,0x0A,0
load_msg         db 'Loading kernel...', 0x0D,0x0A,0
load_success_msg db 'Kernel loaded successfully!', 0x0D,0x0A,0
pm_msg           db 'Entering protected mode (placeholder)...', 0x0D,0x0A,0
disk_error_msg   db 'Disk error!',0x0D,0x0A,0
boot_drive       db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
