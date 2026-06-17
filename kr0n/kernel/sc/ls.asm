; /kernel/sc/ls.asm
; ls - List FAT12 root directory

global str_ls, cmd_ls

section .data
str_ls:        db 'ls', 0
str_ls_hdr:    db 13, 10, 'Directory of /:', 13, 10, 0
str_ls_empty:  db '  (empty)', 13, 10, 0
str_ls_indent: db '  ', 0
str_ls_pad:    db '  ', 0
str_ls_err:    db 'Filesystem error', 13, 10, 0
str_ls_vollbl: db '  <VOL> ', 0

section .bss
ls_sector:     resb 512
ls_count:      resd 1

section .text
cmd_ls:
    pusha

    call fat_init
    jc .err

    mov esi, str_ls_hdr
    call print_string_32

    movzx eax, word [bpb_root_dir_sec]
    mov edi, ls_sector
    call fat_read_sec
    jc .err

    movzx ecx, word [bpb_root_entries]
    xor edx, edx
    mov ebx, ls_sector
    xor edi, edi
    mov [ls_count], edi

.loop:
    test ecx, ecx
    jz .done

    cmp byte [ebx], 0
    je .done
    cmp byte [ebx], 0xE5
    je .skip
    cmp byte [ebx + 11], 0x0F
    je .skip

    test byte [ebx + 11], 0x08
    jnz .vol

    inc dword [ls_count]

    mov esi, str_ls_indent
    call print_string_32

    ; Print 8-byte name
    push ecx
    mov ecx, 8
    mov esi, ebx
.pname:
    lodsb
    cmp al, ' '
    je .pnxt
    call print_char_32
.pnxt:
    loop .pname

    ; Check if extension has non-space
    mov ecx, 3
    mov esi, ebx
    add esi, 8
.ckext:
    lodsb
    cmp al, ' '
    jne .pdot
    loop .ckext
    jmp .pdone

.pdot:
    mov al, '.'
    call print_char_32

    ; Print extension
    mov ecx, 3
    mov esi, ebx
    add esi, 8
.pext:
    lodsb
    cmp al, ' '
    je .penext
    call print_char_32
.penext:
    loop .pext

.pdone:
    pop ecx

    ; Print size
    push edx
    push ebx
    mov esi, str_ls_pad
    call print_string_32
    mov eax, [ebx + 28]
    call print_number_32
    mov al, ' '
    call print_char_32
    mov al, 'b'
    call print_char_32
    pop ebx
    pop edx

    mov al, 13
    call print_char_32
    mov al, 10
    call print_char_32
    jmp .skip

.vol:
    mov esi, str_ls_vollbl
    call print_string_32
    push ecx
    mov ecx, 11
    mov esi, ebx
.vloop:
    lodsb
    cmp al, ' '
    je .vnxt
    call print_char_32
.vnxt:
    loop .vloop
    pop ecx
    mov al, 13
    call print_char_32
    mov al, 10
    call print_char_32

.skip:
    add ebx, 32
    inc edx
    dec ecx
    cmp edx, 16
    jae .adv
    jmp .loop

.adv:
    inc eax
    push ecx
    mov edi, ls_sector
    call fat_read_sec
    pop ecx
    jc .err
    mov ebx, ls_sector
    xor edx, edx
    jmp .loop

.done:
    cmp dword [ls_count], 0
    jnz .end
    mov esi, str_ls_empty
    call print_string_32

.end:
    popa
    ret

.err:
    mov esi, str_ls_err
    call print_string_32
    popa
    ret
