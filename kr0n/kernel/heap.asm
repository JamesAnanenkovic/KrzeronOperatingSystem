; /kernel/heap.asm - Heap Allocator (malloc/free)
; Free-list based, 4-byte header per block.
; Header: dword size (bit 0 = 1 if allocated).
; Free blocks also have a dword next pointer after the header.
; Minimum block size: 16 bytes.

section .data
heap_free_list:  dd 0
heap_brk:        dd 0

MIN_BLOCK      equ 16

section .text

global heap_init
heap_init:
    pushad
    call alloc_page
    test eax, eax
    jz .done
    mov [heap_free_list], eax
    mov [heap_brk], eax
    add dword [heap_brk], 4096
    mov dword [eax], 4096
    mov dword [eax + 4], 0
.done:
    popad
    ret

global malloc
malloc:
    push ecx
    push edx
    push esi
    push edi

    add eax, 3
    and eax, 0xFFFFFFFC
    add eax, 4                  ; total size including header

    mov esi, [heap_free_list]
    xor edi, edi                ; previous free block

.lsearch:
    test esi, esi
    jz .grow

    mov ecx, [esi]
    cmp ecx, eax
    jae .found

    mov edi, esi
    mov esi, [esi + 4]
    jmp .lsearch

.found:
    sub ecx, eax
    cmp ecx, MIN_BLOCK
    jb .nosplit

    ; Split: shrink current block, allocate from its end
    mov [esi], ecx
    add esi, ecx
    mov [esi], eax
    or dword [esi], 1
    lea eax, [esi + 4]
    jmp .done

.nosplit:
    ; Remove from free list entirely
    test edi, edi
    jz .head
    mov edx, [esi + 4]
    mov [edi + 4], edx
    jmp .mark

.head:
    mov edx, [esi + 4]
    mov [heap_free_list], edx

.mark:
    or dword [esi], 1
    lea eax, [esi + 4]
    jmp .done

.grow:
    push eax
    call alloc_page
    test eax, eax
    jz .fail

    mov ecx, [heap_free_list]
    mov [eax], dword 4096
    mov [eax + 4], ecx
    mov [heap_free_list], eax
    pop eax
    jmp .lsearch

.fail:
    xor eax, eax

.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    ret

global free
free:
    test eax, eax
    jz .exit

    push ecx
    push edx
    push esi
    push edi

    sub eax, 4
    mov ecx, [eax]
    and ecx, 0xFFFFFFFE
    mov [eax], ecx              ; mark as free

    ; Find insertion point in sorted free list
    mov esi, [heap_free_list]
    xor edi, edi

.iloop:
    test esi, esi
    jz .itail

    cmp eax, esi
    jb .ibefore

    mov edi, esi
    mov esi, [esi + 4]
    jmp .iloop

.ibefore:
    test edi, edi
    jnz .imid
    mov [eax + 4], esi
    mov [heap_free_list], eax
    jmp .coal
.imid:
    mov [edi + 4], eax
    mov [eax + 4], esi
    jmp .coal

.itail:
    test edi, edi
    jnz .itail2
    mov [heap_free_list], eax
    mov [eax + 4], 0
    jmp .coal
.itail2:
    mov [edi + 4], eax
    mov [eax + 4], 0

.coal:
    ; Coalesce with next
    mov esi, [eax + 4]
    test esi, esi
    jz .coal_prev

    mov ecx, [eax]
    add ecx, eax
    cmp ecx, esi
    jne .coal_prev

    mov ecx, [esi]
    add [eax], ecx
    mov ecx, [esi + 4]
    mov [eax + 4], ecx

.coal_prev:
    test edi, edi
    jz .pret

    mov ecx, [edi]
    add ecx, edi
    cmp ecx, eax
    jne .pret

    mov ecx, [eax]
    add [edi], ecx
    mov ecx, [eax + 4]
    mov [edi + 4], ecx

.pret:
    pop edi
    pop esi
    pop edx
    pop ecx
.exit:
    ret
