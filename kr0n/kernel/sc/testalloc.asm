; /kernel/sc/testalloc.asm
; testalloc - Test heap allocator (malloc/free)
str_testalloc:    db 'testalloc', 0
str_talloc_msg:   db 'Allocated 32 bytes at 0x', 0
str_talloc_ok:    db ', wrote/read OK', 13, 10, 0
str_talloc_fail:  db ', write/read mismatch!', 13, 10, 0
str_talloc_free:  db 'Freed successfully', 13, 10, 0
str_talloc_oom:   db 'malloc returned NULL', 13, 10, 0
str_talloc_nl:    db 13, 10, 0

section .text
global cmd_testalloc
cmd_testalloc:
    pusha

    ; Allocate 32 bytes
    mov eax, 32
    call malloc
    test eax, eax
    jz .oom

    push eax                    ; save ptr

    ; Write pattern
    mov edi, eax
    mov ecx, 8
    mov eax, 0xDEADBEEF
    rep stosd

    ; Print address
    mov esi, str_talloc_msg
    call print_string_32
    pop eax
    push eax
    call print_hex

    ; Read back and verify
    pop esi                     ; ptr in esi
    push esi
    mov ecx, 8
    mov eax, 0xDEADBEEF
    push ecx
.vloop:
    lodsd
    cmp eax, 0xDEADBEEF
    jne .mismatch
    loop .vloop
    pop ecx

    mov esi, str_talloc_ok
    call print_string_32

    ; Free
    pop eax
    call free

    mov esi, str_talloc_free
    call print_string_32
    jmp .done

.mismatch:
    pop ecx
    mov esi, str_talloc_fail
    call print_string_32
    pop eax                     ; discard saved ptr
    jmp .done

.oom:
    mov esi, str_talloc_oom
    call print_string_32

.done:
    popa
    ret

; Print 32-bit value as hex
print_hex:
    pusha
    mov ecx, 8
    mov edi, num_buffer + 11
    mov byte [edi], 0
    dec edi
.loop:
    mov edx, eax
    and edx, 0xF
    cmp dl, 10
    jl .digit
    add dl, 'a' - 10
    jmp .store
.digit:
    add dl, '0'
.store:
    mov [edi], dl
    dec edi
    shr eax, 4
    loop .loop
    inc edi
    mov esi, edi
    call print_string_32
    popa
    ret
