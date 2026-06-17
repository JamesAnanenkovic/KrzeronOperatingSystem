; /kernel/sc/reboot.asm
global cmd_reboot, str_reboot

section .data
str_reboot:     db 'reboot', 0

section .text
cmd_reboot:
    mov al, 0xFE
    out 0x64, al
    ret
