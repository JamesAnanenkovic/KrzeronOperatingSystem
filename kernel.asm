; Kr0nos Kernel - Pure Assembly
bits 16
org 0x0000  ; Will be loaded at 0x1000:0x0000 by the bootloader

; Constants
VIDEO_MEMORY   equ 0xB8000
STACK_TOP      equ 0x9000
PROMPT         db 'kr0nos> ', 0
NEWLINE        db 0x0D, 0x0A, 0

; Kernel entry point
kernel_main:
    ; Set up stack
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, STACK_TOP
    sti

    ; Clear screen
    call clear_screen

    ; Print welcome message
    mov si, welcome_msg
    call print_string

    ; Start shell
    jmp shell_loop

; Shell main loop
shell_loop:
    ; Show prompt
    mov si, PROMPT
    call print_string

    ; Read command
    mov di, command_buffer
    call read_line

    ; Process command
    call process_command
    jmp shell_loop

; Process shell command
process_command:
    pusha
    mov si, command_buffer

    ; Check for empty command
    cmp byte [si], 0
    je .done

    ; Check for 'help' command
    mov di, cmd_help
    call str_compare
    jc .help

    ; Check for 'clear' command
    mov di, cmd_clear
    call str_compare
    jc .clear

    ; Check for 'exit' command
    mov di, cmd_exit
    call str_compare
    jc .exit

    ; Unknown command
    mov si, unknown_cmd_msg
    call print_string
    jmp .done

.help:
    mov si, help_text
    call print_string
    jmp .done

.clear:
    call clear_screen
    jmp .done

.exit:
    mov si, shutdown_msg
    call print_string
    cli                 ; Disable interrupts
    hlt                 ; Halt the CPU
    jmp $               ; Just in case we get here

.done:
    popa
    ret

; Read a line of input into DI
read_line:
    pusha
    mov cx, 0

.read_char:
    ; Read character
    xor ah, ah
    int 0x16

    ; Check for Enter
    cmp al, 0x0D
    je .done_reading

    ; Check for Backspace
    cmp al, 0x08
    je .backspace

    ; Check buffer size
    cmp cx, 79
    jae .read_char

    ; Echo character
    mov ah, 0x0E
    int 0x10

    ; Store character
    stosb
    inc cx
    jmp .read_char

.backspace:
    ; Check if we have characters to delete
    test cx, cx
    jz .read_char

    ; Move cursor back
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10

    ; Remove character from buffer
    dec di
    dec cx
    jmp .read_char

.done_reading:
    ; Null-terminate the string
    mov al, 0
    stosb

    ; Print newline
    mov si, NEWLINE
    call print_string
    popa
    ret

; Print null-terminated string at DS:SI
print_string:
    pusha
    mov ah, 0x0E

.print_char:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_char

.done:
    popa
    ret

; Clear the screen
clear_screen:
    pusha
    mov ax, 0x0700  ; Clear screen
    mov bh, 0x07    ; Attribute (white on black)
    mov cx, 0x0000  ; Top-left corner
    mov dx, 0x184F  ; Bottom-right corner
    int 0x10
    
    ; Move cursor to top-left
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    popa
    ret

; Compare strings at DS:SI and ES:DI
; Sets carry flag if equal
str_compare:
    pusha

.compare:
    cmpsb
    jne .not_equal
    cmp byte [es:di-1], 0
    je .equal
    jmp .compare

.equal:
    stc
    jmp .done

.not_equal:
    clc

.done:
    popa
    ret

; Data
welcome_msg     db 'Kr0nos OS - Simple x86 Assembly OS', 0x0D, 0x0A, 0
help_text       db 'Available commands:', 0x0D, 0x0A
                db '  help  - Show this help', 0x0D, 0x0A
                db '  clear - Clear the screen', 0x0D, 0x0A
                db '  exit  - Shutdown the system', 0x0D, 0x0A, 0
unknown_cmd_msg db 'Unknown command. Type "help" for available commands.', 0x0D, 0x0A, 0
shutdown_msg    db 'System halted. You can now safely turn off your computer.', 0x0D, 0x0A, 0

; Command strings
cmd_help        db 'help', 0
cmd_clear       db 'clear', 0
cmd_exit        db 'exit', 0

; Buffer for command input
command_buffer  times 80 db 0
