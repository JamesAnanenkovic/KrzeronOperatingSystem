; /kernel/kernel.asm - Main Kernel (v0.0.4 Modular)
bits 32
org 0x10000

VIDEO_MEMORY    equ 0xB8000
COLOR_ATTRIBUTE equ 0x07
STACK_TOP       equ 0x200000
KEYBOARD_DATA   equ 0x60
KEYBOARD_STATUS equ 0x64

section .text
kernel_main:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, STACK_TOP
    
    call clear_screen_32
    
    mov esi, welcome_msg
    call print_string_32
    
    jmp shell_loop_32

; ============================================================================
; Screen Routines
; ============================================================================
clear_screen_32:
    pusha
    mov edi, VIDEO_MEMORY
    mov ecx, 2000
    mov ax, 0x0720
    rep stosw
    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    popa
    ret

print_string_32:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    call print_char_32
    jmp .loop
.done:
    popa
    ret

print_char_32:
    pusha
    cmp al, 13
    je .cr
    cmp al, 10
    je .lf
    cmp al, 8
    je .backspace
    
    movzx ebx, byte [cursor_y]
    imul ebx, 80
    movzx ecx, byte [cursor_x]
    add ebx, ecx
    shl ebx, 1
    mov edi, VIDEO_MEMORY
    add edi, ebx
    mov [edi], al
    mov byte [edi+1], COLOR_ATTRIBUTE
    
    inc byte [cursor_x]
    cmp byte [cursor_x], 80
    jl .done
    mov byte [cursor_x], 0
    inc byte [cursor_y]
    cmp byte [cursor_y], 25
    jl .done
    call scroll_screen
.done:
    popa
    ret
.cr:
    mov byte [cursor_x], 0
    popa
    ret
.lf:
    inc byte [cursor_y]
    cmp byte [cursor_y], 25
    jl .done
    call scroll_screen
    popa
    ret
.backspace:
    cmp byte [cursor_x], 0
    je .done
    dec byte [cursor_x]
    jmp .done

scroll_screen:
    pusha
    mov esi, VIDEO_MEMORY + 160
    mov edi, VIDEO_MEMORY
    mov ecx, 1920
    rep movsw
    mov edi, VIDEO_MEMORY + 3840
    mov ecx, 80
    mov ax, 0x0720
    rep stosw
    dec byte [cursor_y]
    popa
    ret

; ============================================================================
; Keyboard Input
; ============================================================================
read_line_32:
    push ebx
    push ecx
    xor ecx, ecx

.read_loop:
    call wait_key
    
    test al, 0x80
    jnz .read_loop
    
    call scancode_to_ascii_v2
    test al, al
    jz .read_loop
    
    cmp al, 13              ; Enter
    je .done
    
    cmp al, 8               ; Backspace
    je .handle_backspace
    
    cmp ecx, 79
    jae .read_loop
    
    push eax
    call print_char_32
    pop eax
    
    mov [edi + ecx], al
    inc ecx
    jmp .read_loop

.handle_backspace:
    test ecx, ecx
    jz .read_loop
    mov al, 8
    call print_char_32
    mov al, ' '
    call print_char_32
    mov al, 8
    call print_char_32
    dec ecx
    jmp .read_loop

.done:
    mov byte [edi + ecx], 0
    mov al, 13
    call print_char_32
    mov al, 10
    call print_char_32
    pop ecx
    pop ebx
    ret

wait_key:
    in al, KEYBOARD_STATUS
    test al, 1
    jz wait_key
    in al, KEYBOARD_DATA
    ret

scancode_to_ascii_v2:
    cmp al, 0x80
    jae .invalid
    movzx ebx, al
    mov al, [scancode_table + ebx]
    ret
.invalid:
    xor al, al
    ret

scancode_table:
    db 0,  27, '1','2','3','4','5','6','7','8','9','0','-','=', 8,  0  ; 0x00-0x0F
    db 'q','w','e','r','t','y','u','i','o','p','[',']', 13,  0, 'a','s' ; 0x10-0x1F  
    db 'd','f','g','h','j','k','l',';', 39,  0,  0,  0,'z','x','c','v' ; 0x20-0x2F
    db 'b','n','m',',','.','/', 0, '*',  0, ' ',  0,  0,  0,  0,  0,  0 ; 0x30-0x3F
    db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0     ; 0x40-0x4F
    db 0,  0,  0,  0,  0,  0,  0,  0                                      ; 0x50-0x57

; ============================================================================
; String Utilities
; ============================================================================
strcmp:
    push eax
.loop:
    mov al, [esi]
    mov ah, [edi]
    cmp al, ah
    jne .ne
    test al, al
    jz .eq
    inc esi
    inc edi
    jmp .loop
.eq:
    stc
    jmp .done
.ne:
    clc
.done:
    pop eax
    ret

; ============================================================================
; Main Shell Loop
; ============================================================================
shell_loop_32:
    mov edi, command_buffer
    mov ecx, 80
    xor al, al
    rep stosb
    
    mov esi, prompt_str
    call print_string_32
    
    mov edi, command_buffer
    call read_line_32
    
    mov esi, command_buffer    ; Load command for dispatcher
    call execute_command       ; Dispatch via command table
    jmp shell_loop_32

; ============================================================================
; Data
; ============================================================================
section .data
welcome_msg     db 'kr0nos v0.0.4', 13, 10, 0
prompt_str      db 'kr0nos> ', 0
str_unknown     db 'Unknown command', 13, 10, 0

section .bss
cursor_x        resb 1         ; Fixed: was dd (dword), now byte
cursor_y        resb 1         ; Fixed: matches byte access in code
command_buffer  resb 80

; ============================================================================
; Include Modular Command System
; ============================================================================
%include "commands.asm"
