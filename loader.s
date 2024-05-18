.segment "LOADER"

.scope

; BASIC loader stub program
.addr loader_term               ; address of next line (program end)
.word 2024                      ; line number
.byte $9e                       ; token for SYS
.asciiz "2061"                  ; address of entry point (ca65 won't compute)
loader_term:
.word 0                         ; program terminator

.endscope

