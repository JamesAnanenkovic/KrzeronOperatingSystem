; kernel/sc/sysinfo.asm
; sysinfo komutu - CPU ve RAM bilgisi gösterir
str_sysinfo:       db 'sysinfo', 0


; ============================================
; Sürücü includes (sadece burada!)
; ============================================
%include "drivers/cpuid.asm"
%include "drivers/memdetect.asm"

section .data
msg_cpu:     db "CPU: ", 0
msg_ram:     db "RAM: ", 0
msg_kb:      db " KB (", 0
msg_mb:      db " MB)", 13, 10, 0
msg_nl:      db 13, 10, 0
msg_err:     db "Error detecting hardware", 13, 10, 0

section .bss
num_buffer:  resb 12

section .text
global cmd_sysinfo

cmd_sysinfo:
    pusha
    
    ; ---- CPU Bilgisi ----
    call cpu_check_support
    test al, al
    jz .cpu_unavailable
    
    call cpu_get_brand
    
    mov esi, msg_cpu
    call print_string_32
    
    call cpu_brand_ptr
    call print_string_32
    
    mov esi, msg_nl
    call print_string_32
    jmp .ram_section
    
.cpu_unavailable:
    mov esi, msg_cpu
    call print_string_32
    
    call cpu_vendor_ptr
    call print_string_32
    
    mov esi, msg_nl
    call print_string_32

.ram_section:
    ; ---- RAM Bilgisi ----
    call mem_init
    jc .ram_error
    
    mov esi, msg_ram
    call print_string_32
    
    ; KB olarak göster
    call mem_get_total_kb
    call print_number_32
    
    mov esi, msg_kb
    call print_string_32
    
    ; MB olarak göster
    call mem_get_total_mb
    call print_number_32
    
    mov esi, msg_mb
    call print_string_32
    jmp .done

.ram_error:
    mov esi, msg_err
    call print_string_32

.done:
    popa
    ret

; ============================================
; 32-bit sayıyı decimal olarak yazdır
; ============================================
print_number_32:
    pusha
    mov ecx, 10
    mov edi, num_buffer + 11
    mov byte [edi], 0
    
    test eax, eax
    jnz .convert_loop
    mov byte [edi-1], '0'
    dec edi
    jmp .print
    
.convert_loop:
    xor edx, edx
    div ecx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .convert_loop
    
.print:
    mov esi, edi
    call print_string_32
    popa
    ret
