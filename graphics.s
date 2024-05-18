.include "color.inc"
.include "graphics.inc"
.include "palette.inc"
.include "sprite.inc"
.include "tiledata.inc"
.include "util.inc"
.include "vera.inc"

.data

color: .res 1
strbuf: .res 7

.code

.proc init_graphics

    ; set DCSEL to 0
    stz VERA::CTRL

    ; disable layers 0 and 1 and sprites
    lda VERA::DC_VIDEO
    and #<(~(VERA::VID_MASK::L0EN | VERA::VID_MASK::L1EN | VERA::VID_MASK::SEN))
    sta VERA::DC_VIDEO

    ; set scale to 2x horizontally vertically
    lda #64
    sta VERA::DC_HSCALE
    sta VERA::DC_VSCALE

    ; set layer 1 scroll position to 0,0
    stz VERA::L1_HSCROLL_L
    stz VERA::L1_HSCROLL_H
    stz VERA::L1_VSCROLL_L
    stz VERA::L1_VSCROLL_H

    ; set layer 1 tile map to 64x32 tiles, 1bpp
    lda #(1 << 4)
    sta VERA::L1_CONFIG

    ; set tiles to 8x8 pixels
    lda VERA::L1_TILEBASE
    and #<(~(VERA::TILEBASE_MASK::HEIGHT | VERA::TILEBASE_MASK::WIDTH))
    sta VERA::L1_TILEBASE

    ; clear layer 1 tile map
    jsr clear_l1_tilemap

    ; load tileset
    jsr load_tiles

    ; load sprite data
    jsr load_sprites

    ; load palette data
    jsr load_palette

    ; enable layer 1 and sprites
    lda VERA::DC_VIDEO
    ora #(VERA::VID_MASK::L1EN | VERA::VID_MASK::SEN)
    sta VERA::DC_VIDEO

    rts

.endproc

.proc clear_l1_tilemap

    ; get tilemap base address into vram_addr
    jsr get_l1_tilemap_base

    ; set vram pointers
    jsr set_vram_addrs

    ; fill 32 rows and 64 columns with spaces, white on black
    ldy #32
yloop:
    ldx #64
xloop:
    lda #' '
    sta VERA::DATA0
    lda #COLOR::WHITE
    sta VERA::DATA1
    dex
    bne xloop
    dey
    bne yloop

    rts

.endproc

.proc load_tiles

    ; get vram address of first letter tile into vram_addr
    jsr get_l1_tileset_base

    ; copy_ram_ptr = letter_tile_data
    lda #<letter_tile_data
    sta copy_ram_ptr
    lda #>letter_tile_data
    sta copy_ram_ptr+1

    ; copy_ram_end = letter_tile_data_end
    lda #<letter_tile_data_end
    sta copy_ram_end
    lda #>letter_tile_data_end
    sta copy_ram_end+1

    ; perform the copy
    jsr copy_ram_to_vram

    ; get vram address of first number tile into vram_addr
    lda #TILE::NUMBER_START
    jsr get_l1_tile_address

    ; copy_ram_ptr = number_tile_data
    lda #<number_tile_data
    sta copy_ram_ptr
    lda #>number_tile_data
    sta copy_ram_ptr+1

    ; copy_ram_end = number_tile_data_end
    lda #<number_tile_data_end
    sta copy_ram_end
    lda #>number_tile_data_end
    sta copy_ram_end+1

    ; perform the copy
    jsr copy_ram_to_vram

    ; get vram address of first graphic tile into vram_addr
    lda #TILE::GRAPHIC_START
    jsr get_l1_tile_address

    ; copy_ram_ptr = graphic_tile_data
    lda #<graphic_tile_data
    sta copy_ram_ptr
    lda #>graphic_tile_data
    sta copy_ram_ptr+1

    ; copy_ram_end = graphic_tile_data_end
    lda #<graphic_tile_data_end
    sta copy_ram_end
    lda #>graphic_tile_data_end
    sta copy_ram_end+1

    ; perform the copy
    jsr copy_ram_to_vram

    ; get vram address of period tile into vram_addr
    lda #TILE::PERIOD
    jsr get_l1_tile_address

    ; copy_ram_ptr = tile_period
    lda #<tile_period
    sta copy_ram_ptr
    lda #>tile_period
    sta copy_ram_ptr+1

    ; copy_ram_end = tile_period_end
    lda #<tile_period_end
    sta copy_ram_end
    lda #>tile_period_end
    sta copy_ram_end+1

    ; perform the copy
    jsr copy_ram_to_vram

    ; get vram address of backtick tile into vram_addr
    lda #TILE::BACKTICK
    jsr get_l1_tile_address

    ; copy_ram_end = tile_backtick_end
    lda #<tile_backtick_end
    sta copy_ram_end
    lda #>tile_backtick_end
    sta copy_ram_end+1

    ; perform the copy
    jsr copy_ram_to_vram

    ; get vram address of backtick tile into vram_addr
    lda #TILE::APOSTROPHE
    jsr get_l1_tile_address

    ; copy_ram_end = tile_apostrophe_end
    lda #<tile_apostrophe_end
    sta copy_ram_end
    lda #>tile_apostrophe_end
    sta copy_ram_end+1

    ; perform the copy
    jmp copy_ram_to_vram

.endproc

; draw a string on the screen horizontally
;
; xcoord - column for first character
; ycoord - row for first character
; color - text color
; copy_ram_ptr - pointer to null-terminated string
.proc draw_string

    jsr coords_to_vram_addr
    jsr set_vram_addrs

loop:
    ldy #0
    lda (copy_ram_ptr),y
    php
    beq increment

    jsr petscii_to_screen_code
    sta VERA::DATA0
    lda color
    sta VERA::DATA1

increment:
    inc copy_ram_ptr
    bne check_done
    inc copy_ram_ptr+1

check_done:
    plp
    bne loop
    rts

.endproc

; draw a string on the screen diagonally, down and to the right
;
; xcoord - top-left column
; ycoord - top-left row
; color - text color
; copy_ram_ptr - pointer to null-terminated string
.proc draw_diagonal_string

loop:
    jsr coords_to_vram_addr
    jsr set_vram_addrs

    ldy #0
    lda (copy_ram_ptr),y
    beq done

    jsr petscii_to_screen_code
    sta VERA::DATA0
    lda color
    sta VERA::DATA1

    inc xcoord
    inc ycoord
    inc copy_ram_ptr
    bne loop
    inc copy_ram_ptr+1
    bra loop

done:
    rts

.endproc
