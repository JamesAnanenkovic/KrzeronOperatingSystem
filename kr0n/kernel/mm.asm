; /kernel/mm.asm - Physical Page Allocator
; Bitmap-based allocator for 4KB pages.
; Each bit = one 4KB page (0 = free, 1 = used).
; Memory layout:
;   0x00000000 - 0x000FFFFF : Reserved (low 1MB: IVT, BDA, kernel, VGA, BIOS)
;   0x00100000 - ...        : Extended memory (usable pages)
;   0x00200000 - 0x00200FFF : Stack (reserved pages 512-515)

section .data
total_pages     dd 0           ; Total 4KB pages in system
free_pages      dd 0           ; Free pages count

section .bss
page_bitmap     resb 2048      ; Covers 16384 pages = up to 64MB RAM

section .text

global mm_init
mm_init:
    pushad

    ; Read extended memory in KB (from bootloader at 0x5000)
    xor eax, eax
    mov ax, [0x5000]
    add eax, 1024               ; total KB = low 1MB + extended
    shr eax, 2                  ; convert to number of 4KB pages
    mov [total_pages], eax

    ; Clear bitmap (all 0 = free)
    mov edi, page_bitmap
    mov ecx, 2048 / 4
    xor eax, eax
    rep stosd

    ; Mark low 1MB as used (pages 0-255)
    xor ebx, ebx
.mark_low:
    cmp ebx, 256
    jae .mark_stack
    bts [page_bitmap], ebx
    inc ebx
    jmp .mark_low

.mark_stack:
    ; Mark stack at 0x200000 as used (pages 512-515, 16KB)
    mov ebx, 512
.mark_stack_loop:
    cmp ebx, 516
    jae .free_high
    bts [page_bitmap], ebx
    inc ebx
    jmp .mark_stack_loop

.free_high:
    ; Free extended memory pages (256+), skipping stack range
    mov ebx, 256
    mov ecx, [total_pages]
.free_loop:
    cmp ebx, ecx
    jae .done_free
    cmp ebx, 512
    jb .do_free
    ; Skip pages 512-515 (stack)
    add ebx, 4
    jmp .free_loop
.do_free:
    btr [page_bitmap], ebx
    inc ebx
    jmp .free_loop

.done_free:
    ; Count free pages
    mov ecx, [total_pages]
    xor ebx, ebx
    xor eax, eax
.count_loop:
    cmp ebx, ecx
    jae .count_done
    bt [page_bitmap], ebx
    jc .count_skip
    inc eax
.count_skip:
    inc ebx
    jmp .count_loop

.count_done:
    mov [free_pages], eax
    popad
    ret

global alloc_page
alloc_page:
    push ecx
    push edx
    xor ecx, ecx
.loop:
    cmp ecx, [total_pages]
    jae .fail
    bt [page_bitmap], ecx
    jnc .found
    inc ecx
    jmp .loop
.found:
    bts [page_bitmap], ecx
    dec dword [free_pages]
    mov eax, ecx
    shl eax, 12
    pop edx
    pop ecx
    ret
.fail:
    xor eax, eax
    pop edx
    pop ecx
    ret

global free_page
free_page:
    push ecx
    push edx
    mov ecx, eax
    shr ecx, 12
    cmp ecx, [total_pages]
    jae .done
    btr [page_bitmap], ecx
    inc dword [free_pages]
.done:
    pop edx
    pop ecx
    ret

global get_free_page_count
get_free_page_count:
    mov eax, [free_pages]
    ret

global get_total_page_count
get_total_page_count:
    mov eax, [total_pages]
    ret
