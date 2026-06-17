; /kernel/sc/version.asm
global cmd_version, str_version

section .data
str_version:    db 'version', 0
str_ver_msg:    db 'kr0nos version: ', KERNEL_VERSION, 13, 10, 0

section .text
cmd_version:
    mov esi, str_ver_msg
    call print_string_32
    ret
