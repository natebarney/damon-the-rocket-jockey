.include "color.inc"
.include "sprite.inc"
.include "spritedata.inc"
.include "vera.inc"

.struct SPRITE_ATTR
    pointer .word
    xpos    .word
    ypos    .word
    colzvh  .byte
    hwpal   .byte
.endstruct

SPRITE_DATA_SIZE_8x8_4BPP = (8 * 8 / 2) >> 5
SPRITE_DATA_SIZE_16x16_4BPP = (16 * 16 / 2) >> 5
SPRITE_DATA_SIZE_32x32_4BPP = (32 * 32 / 2) >> 5
SPRITE_DATA_SIZE_64x32_4BPP = (64 * 32 / 2) >> 5
SPRITE_DATA_SIZE_64x56_4BPP = (64 * 56 / 2) >> 5
SPRITE_DATA_START_PTR = VERA::SPRITE_DATA_VRAM >> 5

PLAYER_BULLET_H_SPRITE_PTR = SPRITE_DATA_START_PTR
PLAYER_BULLET_V_SPRITE_PTR = PLAYER_BULLET_H_SPRITE_PTR + SPRITE_DATA_SIZE_8x8_4BPP
ENEMY_BULLET_H_SPRITE_PTR = PLAYER_BULLET_V_SPRITE_PTR + SPRITE_DATA_SIZE_8x8_4BPP
ENEMY_BULLET_V_SPRITE_PTR = ENEMY_BULLET_H_SPRITE_PTR + SPRITE_DATA_SIZE_8x8_4BPP
PLAYER_H_SPRITE_PTR = ENEMY_BULLET_V_SPRITE_PTR + SPRITE_DATA_SIZE_8x8_4BPP
PLAYER_V_SPRITE_PTR = PLAYER_H_SPRITE_PTR + SPRITE_DATA_SIZE_16x16_4BPP
ENEMY_H_SPRITE_PTR = PLAYER_V_SPRITE_PTR + SPRITE_DATA_SIZE_16x16_4BPP
ENEMY_V_SPRITE_PTR = ENEMY_H_SPRITE_PTR + SPRITE_DATA_SIZE_16x16_4BPP
EXPLOSION_1_SPRITE_PTR = ENEMY_V_SPRITE_PTR + SPRITE_DATA_SIZE_16x16_4BPP
EXPLOSION_2_SPRITE_PTR = EXPLOSION_1_SPRITE_PTR + SPRITE_DATA_SIZE_32x32_4BPP
EXPLOSION_3_SPRITE_PTR = EXPLOSION_2_SPRITE_PTR + SPRITE_DATA_SIZE_32x32_4BPP
SKULL_1_SPRITE_PTR = EXPLOSION_3_SPRITE_PTR + SPRITE_DATA_SIZE_32x32_4BPP
SKULL_2_SPRITE_PTR = SKULL_1_SPRITE_PTR + SPRITE_DATA_SIZE_32x32_4BPP
SKULL_3_SPRITE_PTR = SKULL_2_SPRITE_PTR + SPRITE_DATA_SIZE_32x32_4BPP
D_1_SPRITE_PTR = SKULL_3_SPRITE_PTR + SPRITE_DATA_SIZE_32x32_4BPP
D_2_SPRITE_PTR = D_1_SPRITE_PTR + SPRITE_DATA_SIZE_64x56_4BPP
D_3_SPRITE_PTR = D_2_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
A_1_SPRITE_PTR = D_3_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
A_2_SPRITE_PTR = A_1_SPRITE_PTR + SPRITE_DATA_SIZE_64x56_4BPP
A_3_SPRITE_PTR = A_2_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
M_1_SPRITE_PTR = A_3_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
M_2_SPRITE_PTR = M_1_SPRITE_PTR + SPRITE_DATA_SIZE_64x56_4BPP
M_3_SPRITE_PTR = M_2_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
O_1_SPRITE_PTR = M_3_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
O_2_SPRITE_PTR = O_1_SPRITE_PTR + SPRITE_DATA_SIZE_64x56_4BPP
O_3_SPRITE_PTR = O_2_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
N_1_SPRITE_PTR = O_3_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP
N_2_SPRITE_PTR = N_1_SPRITE_PTR + SPRITE_DATA_SIZE_64x56_4BPP
N_3_SPRITE_PTR = N_2_SPRITE_PTR + SPRITE_DATA_SIZE_64x32_4BPP

.data

sprite_data_ptr: .res 2
sprite_scratch: .res 1
sprite_color: .res 1
sprite_offset: .res 3

.code

.proc load_sprites

    ; set vera address pointer 0 to VERA::SPRITE_DATA_VRAM with 1-byte increment
    stz VERA::CTRL                  ; set ADDRSEL to 0
    lda #<VERA::SPRITE_DATA_VRAM
    sta VERA::ADDR_L
    lda #>VERA::SPRITE_DATA_VRAM
    sta VERA::ADDR_M
    lda #^VERA::SPRITE_DATA_VRAM
    and #VERA::ADDRH_MASK::ADDR16   ; mask off all but address high bit
    ora #(1 << 4)                   ; set address increment to 1
    sta VERA::ADDR_H

    ; copy_ram_ptr = sprite_data
    lda #<sprite_data
    sta copy_ram_ptr
    lda #>sprite_data
    sta copy_ram_ptr+1

    ; copy_ram_end = player_bullet_sprite_data_end
    lda #<player_bullet_sprite_data_end
    sta copy_ram_end
    lda #>player_bullet_sprite_data_end
    sta copy_ram_end+1

    ; set color
    lda #COLOR::CYAN
    sta sprite_color

    ; expand and copy enemy ships
    jsr load_sprite_1bpp_to_4bpp

    ; copy_ram_end = enemy_bullet_sprite_data_end
    lda #<enemy_bullet_sprite_data_end
    sta copy_ram_end
    lda #>enemy_bullet_sprite_data_end
    sta copy_ram_end+1

    ; set color
    lda #COLOR::L_GREY
    sta sprite_color

    ; expand and copy enemy ships
    jsr load_sprite_1bpp_to_4bpp

    ; copy_ram_end = enemy_sprite_data_end
    lda #<enemy_sprite_data_end
    sta copy_ram_end
    lda #>enemy_sprite_data_end
    sta copy_ram_end+1

    ; set color
    lda #COLOR::WHITE
    sta sprite_color

    ; expand and copy player and enemy ships
    jsr load_sprite_1bpp_to_4bpp

    ; copy_ram_end = skull_sprite_data_end
    lda #<skull_sprite_data_end
    sta copy_ram_end
    lda #>skull_sprite_data_end
    sta copy_ram_end+1

    ; expand and copy explosion and skull animations
    jsr load_sprite_24x21_to_32x32_1bpp_to_4bpp

    ; load letter sprites
    ldx #5
loop:
    phx
    jsr load_all_sprites_for_single_letter
    plx
    dex
    bne loop

    rts

.endproc

.proc load_all_sprites_for_single_letter

    ; point copy_ram_end to end of first 24x21 sprite
    clc
    lda copy_ram_ptr
    adc #(24 / 8 * 21)
    sta copy_ram_end
    lda copy_ram_ptr+1
    adc #0
    sta copy_ram_end+1

    ; expand and copy sprite
    jsr load_sprite_24x21_to_64x32_1bpp_to_4bpp

    ; add empty 64x24x4bpp sprite
    ldy #3
loop:
    ldx #0
    jsr write_sprite_padding
    dey
    bne loop

    ; point copy_ram_end to end of third 24x21 sprite
    clc
    lda copy_ram_ptr
    adc #((24 / 8 * 21) * 2)
    sta copy_ram_end
    lda copy_ram_ptr+1
    adc #0
    sta copy_ram_end+1

    ; expand and copy next two sprites
    jmp load_sprite_24x21_to_64x32_1bpp_to_4bpp

.endproc

; copy_ram_ptr - input data pointer
; copy_ram_end - end of input data pointer
; sprite_color - color nibble (low nibble)
.proc load_sprite_1bpp_to_4bpp

byteloop:
    ldy #0
    lda (copy_ram_ptr),y

    ldx #4
bitloop:
    stz sprite_scratch
    asl
    bcc high_nibble_clear
    pha
    lda sprite_color
    asl
    asl
    asl
    asl
    sta sprite_scratch
    pla
high_nibble_clear:
    asl
    bcc low_nibble_clear
    pha
    lda sprite_color
    ora sprite_scratch
    sta sprite_scratch
    pla
low_nibble_clear:
    pha
    lda sprite_scratch
    sta VERA::DATA0
    pla
    dex
    bne bitloop

    ; increment copy_ram_ptr
    inc copy_ram_ptr
    bne nocarry
    inc copy_ram_ptr+1
nocarry:

    ; if copy_ram_ptr < copy_ram_end, go to top of loop
    lda copy_ram_end+1
    cmp copy_ram_ptr+1
    beq compare_low
    bcs byteloop
compare_low:
    lda copy_ram_end
    cmp copy_ram_ptr
    bcc done
    bne byteloop

done:
    rts

.endproc

; X - number of pad bytes
.proc write_sprite_padding

    stz VERA::DATA0
    dex
    bne write_sprite_padding
    rts

.endproc

; copy_ram_ptr - input data pointer
; copy_ram_end - end of input data pointer
; sprite_color - color nibble (low nibble)
.proc load_sprite_24x21_to_32x32_1bpp_to_4bpp

    ldy #21         ; number of source lines per sprite
    ldx #(24 / 8)   ; number of source bytes per sprite line

byteloop:

    phy
    ldy #0
    lda (copy_ram_ptr),y
    ply

    phx
    ldx #4  ; number of output bytes per input byte
bitloop:
    stz sprite_scratch
    asl
    bcc high_nibble_clear
    pha
    lda sprite_color
    asl
    asl
    asl
    asl
    sta sprite_scratch
    pla
high_nibble_clear:
    asl
    bcc low_nibble_clear
    pha
    lda sprite_color
    ora sprite_scratch
    sta sprite_scratch
    pla
low_nibble_clear:
    pha
    lda sprite_scratch
    sta VERA::DATA0
    pla
    dex
    bne bitloop
    plx

    ; increment copy_ram_ptr
    inc copy_ram_ptr
    bne nocarry
    inc copy_ram_ptr+1
nocarry:

    ; check to see if this is the last source byte in the line
    dex
    bne check_end
    ldx #(24 / 8)

    ; pad out line to 32 pixels with empty 4bpp pixels
    phx
    ldx #((32 - 24) / 2)
    jsr write_sprite_padding
    plx

    ; check to see if this is the last source line in the sprite
    dey
    bne check_end
    ldy #21

    ; pad out sprite to 32 lines of 32 pixels with empty 4bpp pixels
    phx
    ldx #((32 - 21) * (32 / 2))
    jsr write_sprite_padding
    plx

check_end:
    ; if copy_ram_ptr < copy_ram_end, go to top of loop
    lda copy_ram_end+1
    cmp copy_ram_ptr+1
    beq compare_low
    bcs byteloop
compare_low:
    lda copy_ram_end
    cmp copy_ram_ptr
    bcc done
    bne byteloop

done:
    rts

.endproc

; copy_ram_ptr - input data pointer
; copy_ram_end - end of input data pointer
; sprite_color - color nibble (low nibble)
.proc load_sprite_24x21_to_64x32_1bpp_to_4bpp

    ldy #21         ; number of source lines per sprite
    ldx #(24 / 8)   ; number of source bytes per sprite line

byteloop:

    phy
    ldy #0
    lda (copy_ram_ptr),y
    ply

    phx
    ldx #8  ; number of output bytes per input byte
bitloop:
    stz sprite_scratch
    asl
    bcc bit_clear
    pha
    lda sprite_color
    asl
    asl
    asl
    asl
    ora sprite_color
    sta sprite_scratch
    pla
bit_clear:
    pha
    lda sprite_scratch
    sta VERA::DATA0
    pla
    dex
    bne bitloop
    plx

    ; increment copy_ram_ptr
    inc copy_ram_ptr
    bne nocarry
    inc copy_ram_ptr+1
nocarry:

    ; check to see if this is the last source byte in the line
    dex
    bne check_end
    ldx #(24 / 8)

    ; pad out line to 64 pixels with empty 4bpp pixels
    phx
    ldx #((64 - 48) / 2)
    jsr write_sprite_padding
    plx

    ; check to see if this is the last source line in the sprite
    dey
    bne check_end
    ldy #21

    ; pad out sprite to 32 lines of 64 pixels with empty 4bpp pixels
    phx
    ldx #((32 - 21) * (32 / 2))
    jsr write_sprite_padding
    ldx #((32 - 21) * (32 / 2))
    jsr write_sprite_padding
    plx

check_end:
    ; if copy_ram_ptr < copy_ram_end, go to top of loop
    lda copy_ram_end+1
    cmp copy_ram_ptr+1
    beq compare_low
    bcs byteloop
compare_low:
    lda copy_ram_end
    cmp copy_ram_ptr
    bcc done
    bne byteloop

done:
    rts

.endproc

; A - sprite number
; Y - byte offset
.proc get_sprite_attr_ptr

    ; sprite_offset = A
    sta sprite_offset
    stz sprite_offset+1

    ; sprite_offset *= 8
    ldx #3
loop:
    asl sprite_offset
    rol sprite_offset+1
    dex
    bne loop

    ; sprite_offset += Y
    clc
    tya
    adc sprite_offset
    sta sprite_offset
    lda sprite_offset+1
    adc #0
    sta sprite_offset+1

    ; vram_addr = VERA::SPRITE_ATTR_VRAM
    lda #<VERA::SPRITE_ATTR_VRAM
    sta vram_addr
    lda #>VERA::SPRITE_ATTR_VRAM
    sta vram_addr+1
    lda #^VERA::SPRITE_ATTR_VRAM
    sta vram_addr+2

    ; vram_addr += sprite_offset
    clc
    lda vram_addr
    adc sprite_offset
    sta vram_addr
    lda vram_addr+1
    adc sprite_offset+1
    sta vram_addr+1
    lda vram_addr+2
    adc #0
    sta vram_addr+2

    rts

.endproc

; a - sprite number
; sprite_data_ptr - high 12 bits of vram pointer to sprite image data
.proc set_sprite_image

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::pointer
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    ora #(1 << 4)   ; address increment 1
    sta VERA::ADDR_H

    lda sprite_data_ptr
    sta VERA::DATA0
    lda sprite_data_ptr+1
    sta VERA::DATA0

    rts

.endproc

; A - sprite number
; X - sprite x position
; Y - sprite y position
.proc set_sprite_pos

    ; save X and Y
    phx
    phy

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::xpos
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    ora #(1 << 4)   ; address increment 1
    sta VERA::ADDR_H

    ; restore X and Y
    ply
    plx

    ; set the position
    stx VERA::DATA0
    stz VERA::DATA0
    sty VERA::DATA0
    stz VERA::DATA0

    rts

.endproc

; A - sprite number
; X - returns sprite x position
; Y - returns sprite y position
.proc get_sprite_pos

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::xpos
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    ora #(2 << 4)   ; address increment 2
    sta VERA::ADDR_H

    ; get the position
    ldx VERA::DATA0
    ldy VERA::DATA0
    rts

.endproc

; A - sprite number
; X - low bit set flips horizontally
; Y - low bit set flips vertically
.proc set_sprite_flip

    phx
    phy

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::colzvh
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    sta VERA::ADDR_H

    ; set vertical flip flag into sprite_scratch
    pla
    and #%00000001
    asl
    sta sprite_scratch

    ; set horizontal flip flag into sprite_scratch
    pla
    and #%00000001
    ora sprite_scratch
    sta sprite_scratch

    ; set the flip flags
    lda VERA::DATA0
    and #%11111100
    ora sprite_scratch
    sta VERA::DATA0

    rts

.endproc

; a - sprite number
; sprite_scratch - bits 2-3 of COLLISION/ZDEPTH/VFLIP/HFLIP register
.proc set_sprite_zdepth

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::colzvh
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    sta VERA::ADDR_H

    ; set the zdepth
    lda VERA::DATA0
    and #%11110011
    ora sprite_scratch
    sta VERA::DATA0

    rts

.endproc

; a - sprite number
; x - 4-bit collision mask (high nibble)
.proc set_sprite_collision_mask

    ; save collision mask
    phx

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::colzvh
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    sta VERA::ADDR_H

    ; mask off low nibble of collision mask and store in sprite_scratch
    pla
    and #%11110000
    sta sprite_scratch

    ; or back in the other bits from the register and set the collision mask
    lda VERA::DATA0
    and #%00001111
    ora sprite_scratch
    sta VERA::DATA0

    rts

.endproc

; a - sprite number
; x - sprite width enum value
; y - sprite height enum value
.proc set_sprite_size

    ; save width and height
    phx
    phy

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::hwpal
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    sta VERA::ADDR_H

    ; mask off height bits and store in sprite_scratch
    pla
    and #%11000000
    sta sprite_scratch

    ; mask off width bits and store in sprite_scratch
    pla
    and #%00110000
    ora sprite_scratch
    sta sprite_scratch

    ; or back in the palette bits from the register and set the size
    lda VERA::DATA0
    and #%00001111
    ora sprite_scratch
    sta VERA::DATA0

    rts

.endproc

; a - sprite number
; x - palette offset (low nibble)
.proc set_sprite_palette_offset

    ; save palette offset
    phx

    ; point VERA address 0 to the selected sprite attribute
    ldy #SPRITE_ATTR::hwpal
    jsr get_sprite_attr_ptr
    stz VERA::CTRL  ; ADDRSEL=0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    sta VERA::ADDR_H

    ; mask off palette bits and store in sprite_scratch
    pla
    and #%00001111
    sta sprite_scratch

    ; or back in the size bits from the register and set the palette
    lda VERA::DATA0
    and #%11110000
    ora sprite_scratch
    sta VERA::DATA0

    rts

.endproc

; a - sprite number
.proc sprite_enable

    ldy #(3 << 2)
    sty sprite_scratch
    jmp set_sprite_zdepth

.endproc

; a - sprite number
.proc sprite_disable

    stz sprite_scratch
    jmp set_sprite_zdepth

.endproc

.proc reset_sprites

    stz VERA::CTRL  ; ADDRSEL=0
    lda #<VERA::SPRITE_ATTR_VRAM
    sta VERA::ADDR_L
    lda #>VERA::SPRITE_ATTR_VRAM
    sta VERA::ADDR_M
    lda #^VERA::SPRITE_ATTR_VRAM
    ora #(1 << 4)   ; address increment 1
    sta VERA::ADDR_H

    ldx #8
loop:
    stz VERA::DATA0
    stz VERA::DATA0
    stz VERA::DATA0
    stz VERA::DATA0
    stz VERA::DATA0
    stz VERA::DATA0
    stz VERA::DATA0
    stz VERA::DATA0
    dex
    bne loop

    rts

.endproc
