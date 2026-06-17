; /kernel/sc/free.asm
; free command - Show physical memory usage
global cmd_free, str_free

str_free:       db 'free', 0
str_free_msg:   db 'Memory: ', 0
str_free_total: db 'Total: ', 0
str_str_pages:  db ' pages (', 0
str_free_kb:    db ' KB)', 13, 10, 0
str_free_avail: db 'Free:  ', 0
str_used:       db 'Used:  ', 0
str_nl:         db 13, 10, 0

section .text
cmd_free:
    pusha

    mov esi, str_free_msg
    call print_string_32

    ; Total pages
    mov esi, str_free_total
    call print_string_32
    call get_total_page_count
    call print_number_32
    mov esi, str_str_pages
    call print_string_32
    call get_total_page_count
    shl eax, 2              ; *4 = KB
    call print_number_32
    mov esi, str_free_kb
    call print_string_32

    ; Free pages
    mov esi, str_free_avail
    call print_string_32
    call get_free_page_count
    call print_number_32
    mov esi, str_str_pages
    call print_string_32
    call get_free_page_count
    shl eax, 2              ; *4 = KB
    call print_number_32
    mov esi, str_free_kb
    call print_string_32

    ; Used pages
    mov esi, str_used
    call print_string_32
    call get_total_page_count
    push eax
    call get_free_page_count
    pop ecx
    sub ecx, eax              ; ecx = total - free
    mov eax, ecx
    push eax
    call print_number_32
    mov esi, str_str_pages
    call print_string_32
    pop eax
    shl eax, 2
    call print_number_32
    mov esi, str_free_kb
    call print_string_32

    popa
    ret
