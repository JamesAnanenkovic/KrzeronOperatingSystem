; /kernel/sc/cat.asm
; cat - Print file contents from FAT12

global str_cat, cmd_cat

section .data
str_cat:       db 'cat', 0
str_cat_usage: db 'Usage: cat <filename>', 13, 10, 0
str_cat_nf:    db 'File not found', 13, 10, 0
str_cat_err:   db 'Error reading file', 13, 10, 0

section .bss
cat_83:        resb 11
cat_buf:       resb 4096

section .text
cmd_cat:
    pusha

    test esi, esi
    jz .usage

    cmp byte [esi], 0
    je .usage

    ; Build 8.3 name: fill with spaces
    mov edi, cat_83
    mov ecx, 11
    mov al, ' '
    rep stosb

    mov edi, cat_83
    xor ebx, ebx

.parse:
    lodsb
    test al, al
    jz .find_file
    cmp al, '.'
    je .parse_ext
    cmp ebx, 8
    jae .parse
    call .toupper
    stosb
    inc ebx
    jmp .parse

.parse_ext:
    mov edi, cat_83 + 8
    xor ebx, ebx
.pex:
    lodsb
    test al, al
    jz .find_file
    cmp ebx, 3
    jae .pex
    call .toupper
    stosb
    inc ebx
    jmp .pex

.find_file:
    call fat_init
    jc .err

    mov esi, cat_83
    call fat_find_file
    jc .nf

    mov ecx, 4096
    mov edi, cat_buf
    call fat_read_file
    jc .err

    mov byte [cat_buf + eax], 0

    test eax, eax
    jz .end

    mov esi, cat_buf
    call print_string_32

.end:
    popa
    ret

.usage:
    mov esi, str_cat_usage
    call print_string_32
    popa
    ret

.nf:
    mov esi, str_cat_nf
    call print_string_32
    popa
    ret

.err:
    mov esi, str_cat_err
    call print_string_32
    popa
    ret

.toupper:
    cmp al, 'a'
    jb .uend
    cmp al, 'z'
    ja .uend
    sub al, 32
.uend:
    ret
