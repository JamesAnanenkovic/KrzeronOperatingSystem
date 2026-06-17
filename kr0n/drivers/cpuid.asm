; drivers/cpuid.asm
; CPU bilgisi sürücüsü

section .data
cpu_vendor:   times 13 db 0
cpu_brand:    times 49 db 0
cpu_has_cpuid: db 0

section .text

global cpu_check_support
cpu_check_support:
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 0x200000
    push eax
    popfd
    pushfd
    pop eax
    xor eax, ecx
    shr eax, 21
    and eax, 1
    push ecx
    popfd
    mov [cpu_has_cpuid], al
    ret

global cpu_get_vendor
cpu_get_vendor:
    mov al, [cpu_has_cpuid]
    test al, al
    jz .no_cpuid
    
    xor eax, eax
    cpuid
    mov [cpu_vendor], ebx
    mov [cpu_vendor+4], edx
    mov [cpu_vendor+8], ecx
    mov byte [cpu_vendor+12], 0
    ret
    
.no_cpuid:
    mov dword [cpu_vendor], "Unkn"
    mov dword [cpu_vendor+4], "own "
    mov byte [cpu_vendor+8], 0
    ret

global cpu_get_brand
cpu_get_brand:
    mov al, [cpu_has_cpuid]
    test al, al
    jz .no_brand
    
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000004
    jb .no_brand
    
    mov eax, 0x80000002
    cpuid
    mov [cpu_brand], eax
    mov [cpu_brand+4], ebx
    mov [cpu_brand+8], ecx
    mov [cpu_brand+12], edx
    
    mov eax, 0x80000003
    cpuid
    mov [cpu_brand+16], eax
    mov [cpu_brand+20], ebx
    mov [cpu_brand+24], ecx
    mov [cpu_brand+28], edx
    
    mov eax, 0x80000004
    cpuid
    mov [cpu_brand+32], eax
    mov [cpu_brand+36], ebx
    mov [cpu_brand+40], ecx
    mov [cpu_brand+44], edx
    mov byte [cpu_brand+48], 0
    ret
    
.no_brand:
    mov dword [cpu_brand], "Unkn"
    mov dword [cpu_brand+4], "own "
    mov dword [cpu_brand+8], "CPU"
    mov byte [cpu_brand+12], 0
    ret

global cpu_vendor_ptr
cpu_vendor_ptr:
    mov esi, cpu_vendor
    ret

global cpu_brand_ptr
cpu_brand_ptr:
    mov esi, cpu_brand
    ret
