; /kernel/sc/testalloc.asm
; testalloc - Heap allocator test suite (malloc/free)
str_testalloc:    db 'testalloc', 0
str_h1:           db 13, 10, '=== Heap Allocator Tests ===', 13, 10, 0
str_t1:           db '[1] Alloc 32, write DEADBEEF, read back, free... ', 0
str_t2a:          db '[2] Alloc 16 + 64 + 128, diff patterns... ', 0
str_t2b:          db '[2] Verify all three... ', 0
str_t2c:          db '[2] Free all... ', 0
str_t3a:          db '[3] Alloc 40... ', 0
str_t3b:          db '[3] Free... ', 0
str_t3c:          db '[3] Realloc 64 (fragmentation test)... ', 0
str_ok:           db 'OK', 13, 10, 0
str_fail:         db 'FAIL', 13, 10, 0
str_oom:          db 'OOM', 13, 10, 0

section .text
global cmd_testalloc
cmd_testalloc:
    pusha

    mov esi, str_h1
    call print_string_32

    ; =========================================
    ; Test 1: Basic alloc/write/read/free
    ; =========================================
    mov esi, str_t1
    call print_string_32

    mov eax, 32
    call malloc
    test eax, eax
    jz .oom1

    push eax
    mov edi, eax
    mov ecx, 8
    mov eax, 0xDEADBEEF
    rep stosd

    mov esi, [esp]
    mov ecx, 8
.t1v:
    lodsd
    cmp eax, 0xDEADBEEF
    jne .fail1
    loop .t1v

    mov esi, str_ok
    call print_string_32

    pop eax
    call free

    ; =========================================
    ; Test 2: Multiple allocs, different sizes & patterns
    ; =========================================
    mov esi, str_t2a
    call print_string_32

    mov eax, 16
    call malloc
    test eax, eax
    jz .oom2
    push eax          ; [esp] = buf1

    mov eax, 64
    call malloc
    test eax, eax
    jz .oom2
    push eax          ; [esp] = buf2, [esp+4] = buf1

    mov eax, 128
    call malloc
    test eax, eax
    jz .oom2
    push eax          ; [esp] = buf3, [esp+4] = buf2, [esp+8] = buf1

    mov esi, str_ok
    call print_string_32

    ; Write patterns: buf1=AA, buf2=BB, buf3=CC
    mov edi, [esp+8]    ; buf1 (largest offset)
    mov ecx, 4
    mov eax, 0xAAAAAAAA
    rep stosd

    mov edi, [esp+4]    ; buf2
    mov ecx, 16
    mov eax, 0xBBBBBBBB
    rep stosd

    mov edi, [esp]      ; buf3
    mov ecx, 32
    mov eax, 0xCCCCCCCC
    rep stosd

    ; Verify all
    mov esi, str_t2b
    call print_string_32

    mov esi, [esp+8]
    mov ecx, 4
    mov eax, 0xAAAAAAAA
.t2v1:
    lodsd
    cmp eax, 0xAAAAAAAA
    jne .fail2
    loop .t2v1

    mov esi, [esp+4]
    mov ecx, 16
    mov eax, 0xBBBBBBBB
.t2v2:
    lodsd
    cmp eax, 0xBBBBBBBB
    jne .fail2
    loop .t2v2

    mov esi, [esp]
    mov ecx, 32
    mov eax, 0xCCCCCCCC
.t2v3:
    lodsd
    cmp eax, 0xCCCCCCCC
    jne .fail2
    loop .t2v3

    mov esi, str_ok
    call print_string_32

    ; Free all (in reverse order)
    mov esi, str_t2c
    call print_string_32

    pop eax
    call free           ; buf3
    pop eax
    call free           ; buf2
    pop eax
    call free           ; buf1

    mov esi, str_ok
    call print_string_32

    ; =========================================
    ; Test 3: Fragmentation - free + realloc larger
    ; =========================================
    mov esi, str_t3a
    call print_string_32

    mov eax, 40
    call malloc
    test eax, eax
    jz .oom3
    push eax            ; [esp] = bufA

    mov edi, eax
    mov ecx, 10
    mov eax, 0xA5A5A5A5
    rep stosd

    mov esi, str_ok
    call print_string_32

    mov esi, str_t3b
    call print_string_32

    mov eax, [esp]
    call free           ; free bufA

    mov esi, str_ok
    call print_string_32

    mov esi, str_t3c
    call print_string_32

    mov eax, 64
    call malloc         ; should reuse bufA's space (or split adjacent)
    test eax, eax
    jz .oom3
    push eax            ; [esp] = bufC, [esp+4] = bufA (freed)

    mov edi, eax
    mov ecx, 16
    mov eax, 0xDDDDDDDD
    rep stosd

    mov esi, [esp]
    mov ecx, 16
    mov eax, 0xDDDDDDDD
.t3v:
    lodsd
    cmp eax, 0xDDDDDDDD
    jne .fail3
    loop .t3v

    mov esi, str_ok
    call print_string_32

    pop eax
    call free           ; bufC
    pop eax             ; discard bufA (already freed)

    ; =========================================
    ; Done
    ; =========================================
    popa
    ret

.oom1:
    mov esi, str_oom
    call print_string_32
    pop eax
    jmp .done

.oom2:
    mov esi, str_oom
    call print_string_32
    ; Clean up partial allocs on stack
    test esp, esp
    add esp, 12         ; pop up to 3 saved ptrs
    jmp .done

.oom3:
    mov esi, str_oom
    call print_string_32
    add esp, 4
    jmp .done

.fail1:
    mov esi, str_fail
    call print_string_32
    pop eax
    jmp .done

.fail2:
    mov esi, str_fail
    call print_string_32
    add esp, 12
    jmp .done

.fail3:
    mov esi, str_fail
    call print_string_32
    add esp, 8
    jmp .done

.done:
    popa
    ret
