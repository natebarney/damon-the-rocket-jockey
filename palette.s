.include "palette.inc"
.include "vera.inc"

.code

.proc load_palette

    ; vram_addr = VERA::PALETTE_VRAM
    lda #<VERA::PALETTE_VRAM
    sta vram_addr
    lda #>VERA::PALETTE_VRAM
    sta vram_addr+1
    lda #^VERA::PALETTE_VRAM
    sta vram_addr+2

    ; copy_ram_ptr = palette_data
    lda #<palette_data
    sta copy_ram_ptr
    lda #>palette_data
    sta copy_ram_ptr+1

    ; copy_ram_end = palette_data_end
    lda #<palette_data_end
    sta copy_ram_end
    lda #>palette_data_end
    sta copy_ram_end+1

    ; perform the copy
    jsr copy_ram_to_vram

    ; set vera address pointer 0 to low byte of palette entry $11
    stz VERA::CTRL                          ; set ADDRSEL to 0
    lda #<(VERA::PALETTE_VRAM + $11 * 2)
    sta VERA::ADDR_L
    lda #>(VERA::PALETTE_VRAM + $11 * 2)
    sta VERA::ADDR_M
    lda #^(VERA::PALETTE_VRAM + $11 * 2)
    and #VERA::ADDRH_MASK::ADDR16           ; mask off all but address high bit
    ora #(6 << 4)                           ; set address increment to 32
    sta VERA::ADDR_H

    ; set vera address pointer 1 to high byte of palette entry $11
    inc VERA::CTRL                          ; set ADDRSEL to 1
    lda #<(VERA::PALETTE_VRAM + $11 * 2 + 1)
    sta VERA::ADDR_L
    lda #>(VERA::PALETTE_VRAM + $11 * 2 + 1)
    sta VERA::ADDR_M
    lda #^(VERA::PALETTE_VRAM + $11 * 2 + 1)
    and #VERA::ADDRH_MASK::ADDR16           ; mask off all but address high bit
    ora #(6 << 4)                           ; set address increment to 32
    sta VERA::ADDR_H

    ; copy_ram_ptr = palette_extra_data
    lda #<palette_extra_data
    sta copy_ram_ptr
    lda #>palette_extra_data
    sta copy_ram_ptr+1

    ; copy in extra palette data under column 1 (white)
    ldy #0
loop:
    lda (copy_ram_ptr),y
    sta VERA::DATA0
    iny
    lda (copy_ram_ptr),y
    sta VERA::DATA1
    iny
    cpy #<(palette_extra_data_end - palette_extra_data)
    bne loop

    rts

.endproc

.rodata

palette_data:

; first row (Commander X16 Primary Palette)
.word $0000 ; 00: black
.word $0fff ; 01: white
.word $0800 ; 02: red
.word $0afe ; 03: cyan
.word $0c4c ; 04: purple
.word $00c5 ; 05: green
.word $000a ; 06: blue
.word $0ee7 ; 07: yellow
.word $0d85 ; 08: orange
.word $0640 ; 09: brown
.word $0f77 ; 0A: light red
.word $0333 ; 0B: dark grey
.word $0777 ; 0C: medium grey
.word $0af6 ; 0D: light green
.word $008f ; 0E: light blue
.word $0bbb ; 0F: light grey

palette_data_end:

palette_extra_data:

; second column (under white)
.word $0c4c ; 11: purple (enemy 0)
.word $00c5 ; 21: green (enemy 1)
.word $008f ; 31: light blue (enemy 2. The original had blue here, but
            ;                 it's too dark on the Commander X16. If I tweak the
            ;                 palette to be more C64-like, this should maybe be
            ;                 revisited)
.word $0ee7 ; 41: yellow (enemy 3)
.word $0d85 ; 51: orange (enemy 4)
.word $0f77 ; 61: light red (enemy explosion. The original had red here, but
            ;                it's too dark on the Commander X16. If I tweak the
            ;                palette to be more C64-like, this should maybe be
            ;                revisited)
.word $0afe ; 71: cyan (title A letter)

palette_extra_data_end:
