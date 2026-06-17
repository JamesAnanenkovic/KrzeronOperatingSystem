; drivers/fat.asm - FAT12 Filesystem Driver
; Uses ATA PIO LBA28 (primary master) for disk I/O.
; Caches BPB from sector 0, provides file lookup + cluster chain read.

section .data
bpb_bytes_per_sec:   dw 512
bpb_sec_per_cluster: db 1
bpb_reserved_sec:    dw 1
bpb_fat_count:       db 2
bpb_root_entries:    dw 224
bpb_sectors_per_fat: dw 9
bpb_root_dir_sec:    dw 0
bpb_first_data_sec:  dw 0

section .bss
fat_buf:            resb 512       ; scratch sector buffer
fat_cluster:        resd 1
fat_bufptr:         resd 1
fat_max:            resd 1

section .text

; Read one sector (LBA in eax) into buffer (edi)
fat_read_sec:
    push ecx
    mov ecx, 1
    call ata_read_sectors
    pop ecx
    ret

; Initialize: read BPB from LBA 0, calculate disk geometry
global fat_init
fat_init:
    pushad
    mov edi, fat_buf
    xor eax, eax
    call fat_read_sec
    jc .fail

    mov ax, [fat_buf + 11]
    mov [bpb_bytes_per_sec], ax
    mov al, [fat_buf + 13]
    mov [bpb_sec_per_cluster], al
    mov ax, [fat_buf + 14]
    mov [bpb_reserved_sec], ax
    mov al, [fat_buf + 16]
    mov [bpb_fat_count], al
    mov ax, [fat_buf + 17]
    mov [bpb_root_entries], ax
    mov ax, [fat_buf + 22]
    mov [bpb_sectors_per_fat], ax

    ; root_dir_sec = reserved + (fats * sectors_per_fat)
    movzx eax, word [bpb_reserved_sec]
    movzx ecx, byte [bpb_fat_count]
    movzx edx, word [bpb_sectors_per_fat]
    imul ecx, edx
    add eax, ecx
    mov [bpb_root_dir_sec], ax

    ; root_dir_sectors = (root_entries * 32 + bytes_per_sec - 1) / bytes_per_sec
    movzx eax, word [bpb_root_entries]    ; 224
    shl eax, 5                             ; * 32 = 7168
    movzx ecx, word [bpb_bytes_per_sec]   ; 512
    push ecx                               ; save divisor
    dec ecx                                ; 511
    add eax, ecx                           ; 7168 + 511 = 7679
    xor edx, edx
    pop ecx                                ; restore 512 as divisor
    div ecx                                ; eax = 7679 / 512 = 14
    push eax                               ; save root_dir_sectors

    ; first_data_sec = root_dir_sec + root_dir_sectors
    movzx eax, word [bpb_root_dir_sec]
    pop ecx
    add eax, ecx
    mov [bpb_first_data_sec], ax

    clc
    popad
    ret
.fail:
    stc
    popad
    ret

; Convert cluster number to LBA
; Input:  eax = cluster number (2-based)
; Output: eax = LBA
cluster_to_lba:
    sub eax, 2
    movzx ecx, byte [bpb_sec_per_cluster]
    imul eax, ecx
    movzx ecx, word [bpb_first_data_sec]
    add eax, ecx
    ret

; Read a 12-bit FAT entry
; Input:  eax = cluster number
; Output: eax = next cluster (0xFF8-0xFFF = EOF), carry on error
global fat_next_cluster
fat_next_cluster:
    push ecx
    push edx
    push esi

    push eax
    mov ecx, eax
    shl eax, 1
    add eax, ecx
    shr eax, 1

    xor edx, edx
    movzx ecx, word [bpb_bytes_per_sec]
    div ecx

    push edx
    movzx ecx, word [bpb_reserved_sec]
    add eax, ecx
    mov edi, fat_buf
    call fat_read_sec
    pop edx
    jc .fail

    mov esi, fat_buf
    add esi, edx
    mov ax, [esi]

    pop ecx
    test ecx, 1
    jnz .odd
    and ax, 0x0FFF
    jmp .got
.odd:
    shr ax, 4
.got:
    movzx eax, ax
    clc
    pop esi
    pop edx
    pop ecx
    ret
.fail:
    add esp, 4
    stc
    pop esi
    pop edx
    pop ecx
    ret

; Find file in root directory
; Input:  esi = pointer to 11-byte 8.3 filename (e.g., "README  TXT")
; Output: eax = first cluster (0 = not found), carry = 0 found, 1 = not found
global fat_find_file
fat_find_file:
    push ecx
    push edx
    push edi
    push esi

    movzx eax, word [bpb_root_dir_sec]
    movzx ecx, word [bpb_root_entries]

.next_sec:
    push eax
    push ecx
    mov edi, fat_buf
    call fat_read_sec
    pop ecx
    pop eax
    jc .fail

    xor edx, edx
.entry:
    cmp edx, 16
    jae .adv_sec
    test ecx, ecx
    jz .nf

    mov edi, fat_buf
    imul ebx, edx, 32
    add edi, ebx

    cmp byte [edi], 0
    je .nf
    cmp byte [edi], 0xE5
    je .skip
    cmp byte [edi + 11], 0x0F
    je .skip

    push ecx
    push esi
    push edi
    mov ecx, 11
    cld
    repz cmpsb
    pop edi
    pop esi
    pop ecx
    jne .skip

    movzx eax, word [edi + 26]
    clc
    jmp .done

.skip:
    inc edx
    dec ecx
    jmp .entry

.adv_sec:
    inc eax
    jmp .next_sec

.nf:
.fail:
    stc
    xor eax, eax
.done:
    pop esi
    pop edi
    pop edx
    pop ecx
    ret

; Read file content into buffer
; Input:  eax = first cluster, edi = buffer, ecx = max bytes
; Output: eax = bytes read, carry on error
global fat_read_file
fat_read_file:
    push ecx
    push edx
    push esi
    push edi

    mov [fat_cluster], eax
    mov [fat_bufptr], edi
    mov [fat_max], ecx
    xor esi, esi

.cloop:
    mov eax, [fat_cluster]
    cmp eax, 0x0FF8
    jae .done

    call cluster_to_lba
    movzx ecx, byte [bpb_sec_per_cluster]
    mov edi, [fat_bufptr]
    call ata_read_sectors
    jc .fail

    movzx eax, byte [bpb_sec_per_cluster]
    movzx edx, word [bpb_bytes_per_sec]
    imul eax, edx
    add [fat_bufptr], eax
    add esi, eax
    sub [fat_max], eax
    jbe .done

    mov eax, [fat_cluster]
    call fat_next_cluster
    jc .fail
    mov [fat_cluster], eax
    jmp .cloop

.done:
    mov eax, esi
    clc
    jmp .end
.fail:
    stc
.end:
    pop edi
    pop esi
    pop edx
    pop ecx
    ret
