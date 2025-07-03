BITS 64
ORG 0x00200000

; PE Header
db 'MZ'                    ; DOS Magic number
times 0x3E db 0           ; Reserved bytes
dd 0x00000080            ; Offset to PE header

; PE Header
db 'PE', 0, 0            ; PE Signature
dw 0x8664                ; Machine (x64)
dw 1                     ; Number of sections
dd 0                     ; Timestamp
dd 0                     ; Symbol table pointer
dd 0                     ; Number of symbols
dw 0xF0                  ; Optional header size
dw 0x22F                 ; Characteristics

; Optional Header
dw 0x20B                 ; PE32+ format
db 0x02                  ; Linker version
db 0x14                  ; Size of code
dd 0x1000                ; Size of initialized data
dd 0                     ; Size of uninitialized data
dd start                 ; Entry point
dd 0x1000                ; Base of code

; Data directories
times 0x70 db 0          ; Empty data directories

; Section header
db '.text', 0, 0, 0      ; Section name
dd 0x1000                ; Virtual size
dd 0x1000                ; Virtual address
dd 0x1000                ; Size of raw data
dd 0x1000                ; Pointer to raw data
dd 0                     ; Pointer to relocations
dd 0                     ; Pointer to line numbers
dw 0                     ; Number of relocations
dw 0                     ; Number of line numbers
dd 0x60000020           ; Characteristics

; Code section
align 0x1000
start:
    ; Simple UEFI bootloader
    mov rax, message
    call print_string
    jmp $                ; Infinite loop

message: db "UEFI Boot Test", 0x0D, 0x0A, 0

print_string:
    push rax
    mov rbx, 0           ; String length counter
.loop:
    mov cl, [rax + rbx]
    test cl, cl
    jz .done
    inc rbx
    jmp .loop
.done:
    pop rax
    ret

; Pad to section alignment
align 0x1000 