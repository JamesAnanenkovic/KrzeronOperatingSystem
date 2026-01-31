; /kernel/commands.asm - Command Registry and Dispatcher
; Wires together all command modules from /kernel/sc/

struc cmd_entry
    .name: resd 1
    .func: resd 1
endstruc

; Include command implementations
%include "sc/help.asm"
%include "sc/clear.asm"
%include "sc/about.asm"
%include "sc/exit.asm"
%include "sc/read.asm"       ; NEW: Experimental disk read
%include "sc/uname.asm"      ; NEW: System info

section .data
align 4
command_table:
    istruc cmd_entry
        at cmd_entry.name, dd str_help
        at cmd_entry.func, dd cmd_help
    iend
    istruc cmd_entry
        at cmd_entry.name, dd str_clear
        at cmd_entry.func, dd cmd_clear
    iend
    istruc cmd_entry
        at cmd_entry.name, dd str_about
        at cmd_entry.func, dd cmd_about
    iend
    istruc cmd_entry
        at cmd_entry.name, dd str_exit
        at cmd_entry.func, dd cmd_exit
    iend
    istruc cmd_entry           ; NEW ENTRY
        at cmd_entry.name, dd str_read
        at cmd_entry.func, dd cmd_read
    iend
    istruc cmd_entry           ; NEW ENTRY
        at cmd_entry.name, dd str_uname
        at cmd_entry.func, dd cmd_uname
    iend
    dd 0, 0                    ; Null terminator

section .text
global execute_command
execute_command:
    pusha
    mov ebx, command_table
    
.search_loop:
    mov edi, [ebx + cmd_entry.name]
    test edi, edi
    jz .not_found
    
    push esi
    call strcmp
    pop esi
    jc .found
    
    add ebx, 8
    jmp .search_loop
    
.found:
    mov eax, [ebx + cmd_entry.func]
    call eax
    popa
    ret
    
.not_found:
    mov esi, str_unknown
    call print_string_32
    popa
    ret
