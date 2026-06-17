; /kernel/commands.asm - Command Registry and Dispatcher

; ============================================
; Sürücüler (tüm komutlar için ortak)
; ============================================
%include "drivers/ata.asm"
%include "drivers/fat.asm"

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
%include "sc/uptime.asm"
%include "sc/sleep.asm"
%include "sc/version.asm"
%include "sc/reboot.asm"
%include "sc/free.asm"
%include "sc/testalloc.asm"
%include "sc/ls.asm"
%include "sc/cat.asm"

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
    dd str_about,   cmd_about
    dd str_exit,    cmd_exit
    dd str_read,    cmd_read
    dd str_uname,   cmd_uname
    dd str_sysinfo, cmd_sysinfo
    dd str_uptime,  cmd_uptime
    dd str_sleep,   cmd_sleep
    dd str_version, cmd_version
    dd str_clr,     cmd_clr
    dd str_reboot,  cmd_reboot
    dd str_free,    cmd_free
    dd str_testalloc, cmd_testalloc
    dd str_ls,      cmd_ls
    dd str_cat,     cmd_cat
    dd 0, 0                    ; Null terminator

section .text
global execute_command

; ============================================
; Komut çalıştırıcı
; ============================================
execute_command:
    pusha
    mov ebx, command_table
    
    ; Find first space or null in command buffer
    mov edi, esi
    xor ecx, ecx
.find_end:
    cmp byte [edi + ecx], 0
    je .no_arg
    cmp byte [edi + ecx], ' '
    je .has_arg
    inc ecx
    jmp .find_end
    
.has_arg:
    mov byte [edi + ecx], 0     ; null-terminate command name
    lea edx, [edi + ecx + 1]    ; arg pointer
    jmp .search
    
.no_arg:
    xor edx, edx               ; no args
    
.search:
    mov edi, [ebx]              ; name pointer
    test edi, edi
    jz .not_found
    
    push esi
    push edi
    pop edi
    pop esi
    push esi
    call strcmp
    pop esi
    
    test eax, eax
    jz .found
    
    add ebx, 8
    jmp .search
    
.found:
    test edx, edx
    jz .call_handler
    mov byte [edx - 1], ' '     ; restore space
    
.call_handler:
    mov eax, [ebx + 4]          ; function pointer
    mov esi, edx                ; pass arg pointer (or 0)
    call eax
    popa
    ret
    
.not_found:
    test edx, edx
    jz .print_unknown
    mov byte [edx - 1], ' '
    
.print_unknown:
    mov esi, str_unknown
    call print_string_32
    popa
    ret
