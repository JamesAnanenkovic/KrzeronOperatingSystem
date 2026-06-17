; /kernel/commands.asm - Command Registry and Dispatcher

; ============================================
; Komut implementasyonları
; ============================================
%include "sc/help.asm"
%include "sc/clear.asm"
%include "sc/about.asm"
%include "sc/exit.asm"
%include "sc/read.asm"       
%include "sc/uname.asm"
%include "sc/sysinfo.asm"

section .data
align 4

; ============================================
; Komut isimleri
; ============================================

; ============================================
; Komut tablosu
; ============================================
command_table:
    dd str_help,    cmd_help
    dd str_clear,   cmd_clear
    dd str_about,   cmd_about
    dd str_exit,    cmd_exit
    dd str_read,    cmd_read
    dd str_uname,   cmd_uname
    dd str_sysinfo, cmd_sysinfo
    dd 0, 0                    ; Null terminator

section .text
global execute_command

; ============================================
; Komut çalıştırıcı
; ============================================
execute_command:
    pusha
    mov ebx, command_table
    
.search_loop:
    mov edi, [ebx]          ; name pointer
    test edi, edi
    jz .not_found
    
    ; Karşılaştır
    push esi
    push edi
    pop edi
    pop esi
    push esi
    call strcmp             ; kernel.asm'den geliyor
    pop esi
    
    test eax, eax
    jz .found
    
    add ebx, 8              ; sonraki giriş
    jmp .search_loop
    
.found:
    mov eax, [ebx + 4]      ; function pointer
    call eax
    popa
    ret
    
.not_found:
    mov esi, str_unknown
    call print_string_32
    popa
    ret
