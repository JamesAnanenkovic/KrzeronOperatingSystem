; drivers/ata.asm - ATA PIO LBA28 Driver
; Primary ATA bus: ports 0x1F0-0x1F7, 0x3F6
; Supports read of 1-255 sectors via LBA28.

ATA_DATA         equ 0x1F0
ATA_ERROR        equ 0x1F1
ATA_SECTOR_COUNT equ 0x1F2
ATA_LBA_LOW      equ 0x1F3
ATA_LBA_MID      equ 0x1F4
ATA_LBA_HIGH     equ 0x1F5
ATA_DRIVE        equ 0x1F6
ATA_COMMAND      equ 0x1F7
ATA_STATUS       equ 0x1F7

ATA_SR_BSY       equ 0x80
ATA_SR_DRDY      equ 0x40
ATA_SR_DRQ       equ 0x08
ATA_SR_ERR       equ 0x01

ATA_CMD_READ     equ 0x20

section .text

; Wait for BSY=0 (status port in dx)
; Output: carry = 0 on success, 1 on timeout
ata_wait_bsy:
    push ecx
    mov ecx, 1000000
.loop:
    in al, dx
    test al, ATA_SR_BSY
    jz .ok
    loop .loop
    stc
    pop ecx
    ret
.ok:
    clc
    pop ecx
    ret

; Wait for DRQ=1 after BSY=0 (status port in dx)
; Output: carry = 0 on success, 1 on error/timeout
ata_wait_drq:
    push ecx
    call ata_wait_bsy
    jc .fail
    mov ecx, 1000000
.loop:
    in al, dx
    test al, ATA_SR_DRQ
    jnz .ok
    test al, ATA_SR_ERR
    jnz .fail
    loop .loop
.fail:
    stc
    pop ecx
    ret
.ok:
    clc
    pop ecx
    ret

; Read sectors via ATA PIO LBA28
; Input:  eax = LBA (28-bit)
;         ecx = sector count (1-255)
;         edi = destination buffer
; Output: carry = 0 on success, 1 on error
global ata_read_sectors
ata_read_sectors:
    push ebp
    mov ebp, esp
    push eax               ; [ebp-4]  = LBA
    push ecx               ; [ebp-8]  = count
    push edx
    push edi

    ; Wait for drive ready
    mov dx, ATA_STATUS
    call ata_wait_bsy
    jc .fail

    ; Drive/Head: 0xE0 | (LBA >> 24) & 0x0F
    mov eax, [ebp - 4]     ; LBA
    mov dx, ATA_DRIVE
    shr eax, 24
    and al, 0x0F
    or  al, 0xE0
    out dx, al

    ; Sector count
    mov ecx, [ebp - 8]
    mov dx, ATA_SECTOR_COUNT
    mov al, cl
    out dx, al

    ; LBA low (bits 0-7)
    mov eax, [ebp - 4]
    mov dx, ATA_LBA_LOW
    out dx, al

    ; LBA mid (bits 8-15)
    shr eax, 8
    mov dx, ATA_LBA_MID
    out dx, al

    ; LBA high (bits 16-23)
    shr eax, 8
    mov dx, ATA_LBA_HIGH
    out dx, al

    ; Read command
    mov dx, ATA_COMMAND
    mov al, ATA_CMD_READ
    out dx, al

    ; Wait for DRQ
    call ata_wait_drq
    jc .fail

    ; Read 256 words (512 bytes) from data port
    mov dx, ATA_DATA
    mov ecx, 256
    rep insw

    clc
    jmp .done

.fail:
    stc

.done:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop ebp
    ret
