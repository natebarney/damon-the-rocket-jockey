.include "barrier.inc"
.include "color.inc"
.include "graphics.inc"
.include "level.inc"
.include "pellet.inc"
.include "score.inc"
.include "tiledata.inc"
.include "vera.inc"

TILE_SIZE = 8 ; in pixels
BORDER_THICKNESS = TILE_SIZE ; in pixels
BLOCK_SIZE = TILE_SIZE * 2 ; in pixels
BOARD_WIDTH = 15 ; in blocks (without border)
BOARD_HEIGHT = 11 ; in blocks (without border)

BOARD_XMIN = 0 ; in tiles
BOARD_YMIN = 3 ; in tiles

.rodata

score_str: .asciiz "SCORE"
ships_str: .asciiz "SHIPS"
level_str: .asciiz "LEVEL"
hiscore_str: .asciiz "HISCORE"

level_glyphs:

; level 1 glyphs
.byte TILE::LEVEL1_TOP_LEFT
.byte TILE::LEVEL1_TOP_RIGHT
.byte TILE::LEVEL1_BOTTOM_LEFT
.byte TILE::LEVEL1_BOTTOM_RIGHT

; level 2 glyphs
.byte TILE::LEVEL2
.byte TILE::LEVEL2
.byte TILE::LEVEL2
.byte TILE::LEVEL2

; level 3 glyphs
.byte TILE::LEVEL3
.byte TILE::LEVEL3
.byte TILE::LEVEL3
.byte TILE::LEVEL3

; level 4 glyphs
.byte TILE::LEVEL4
.byte TILE::LEVEL4
.byte TILE::LEVEL4
.byte TILE::LEVEL4

; level 5 glyphs
.byte TILE::LEVEL5_TOP_LEFT
.byte TILE::LEVEL5_TOP_RIGHT
.byte TILE::LEVEL5_BOTTOM_LEFT
.byte TILE::LEVEL5_BOTTOM_RIGHT

level_color:
.byte COLOR::GREEN      ; level 1
.byte COLOR::BROWN      ; level 2
.byte COLOR::M_GREY     ; level 3
.byte COLOR::ORANGE     ; level 4
.byte COLOR::L_RED      ; level 5
.byte COLOR::CYAN       ; level 6
.byte COLOR::YELLOW     ; level 7
.byte COLOR::WHITE      ; level 8
.byte COLOR::L_BLUE     ; level 9
.byte COLOR::L_GREEN    ; level 10

.code

.proc draw_level_screen

    jsr clear_l1_tilemap
    jsr draw_border
    jsr draw_level_blocks
    jsr draw_pellets
    jmp draw_barriers

.endproc

.proc draw_border

    lda #BOARD_XMIN
    sta xcoord
    lda #BOARD_YMIN
    sta ycoord
    lda #TILE::BORDER_TOP_LEFT
    sta glyphs
    lda #TILE::BORDER_TEE_DOWN
    sta glyphs+1
    lda #TILE::BORDER_TOP_RIGHT
    sta glyphs+2
    jsr draw_horizontal_border

    lda #BOARD_XMIN
    sta xcoord
    lda #BOARD_YMIN + 1
    sta ycoord
    jsr draw_vertical_border

    lda #BOARD_XMIN + 31
    sta xcoord
    lda #BOARD_YMIN + 1
    sta ycoord
    jsr draw_vertical_border

    lda #BOARD_XMIN + 39
    sta xcoord
    lda #BOARD_YMIN + 1
    sta ycoord
    jsr draw_vertical_border

    lda #BOARD_XMIN
    sta xcoord
    lda #BOARD_YMIN + 23
    sta ycoord
    lda #TILE::BORDER_BOTTOM_LEFT
    sta glyphs
    lda #TILE::BORDER_TEE_UP
    sta glyphs+1
    lda #TILE::BORDER_BOTTOM_RIGHT
    sta glyphs+2
    jsr draw_horizontal_border

    jmp draw_score_area

.endproc

.proc draw_horizontal_border

    ; set vram pointers to beginning of selected line
    jsr coords_to_vram_addr
    jsr set_vram_addrs

    ; left corner
    lda glyphs
    sta VERA::DATA0
    lda #COLOR::PURPLE
    sta VERA::DATA1

    ; first bar
    ldy #30
loop1:
    lda #TILE::BORDER_HORIZONTAL
    sta VERA::DATA0
    lda #COLOR::PURPLE
    sta VERA::DATA1
    dey
    bne loop1

    ; t-junction
    lda glyphs+1
    sta VERA::DATA0
    lda #COLOR::PURPLE
    sta VERA::DATA1

    ; second bar
    ldy #7
loop2:
    lda #TILE::BORDER_HORIZONTAL
    sta VERA::DATA0
    lda #COLOR::PURPLE
    sta VERA::DATA1
    dey
    bne loop2

    ; right corner
    lda glyphs+2
    sta VERA::DATA0
    lda #COLOR::PURPLE
    sta VERA::DATA1

    rts

.endproc

.proc draw_vertical_border

    ; set vram pointers
    jsr coords_to_vram_addr
    jsr set_vram_addrs

    ; adjust address 0 increment to 128 (one line)
    stz VERA::CTRL
    lda VERA::ADDR_H
    and #<(~(VERA::ADDRH_MASK::ADDR_INCR))
    ora #(8 << 4)
    sta VERA::ADDR_H

    ; adjust address 1 increment to 128 (one line)
    lda #1
    sta VERA::CTRL
    lda VERA::ADDR_H
    and #<(~(VERA::ADDRH_MASK::ADDR_INCR))
    ora #(8 << 4)
    sta VERA::ADDR_H

    ; draw vertical border
    ldy #22
loop:
    lda #TILE::BORDER_VERTICAL
    sta VERA::DATA0
    lda #COLOR::PURPLE
    sta VERA::DATA1
    dey
    bne loop

    rts

.endproc

.proc draw_score_area

    lda #BOARD_YMIN + 1
    sta ycoord
    lda #BOARD_YMIN + 23
    sta yend

yloop:
    lda #BOARD_XMIN + 32
    sta xcoord
    jsr coords_to_vram_addr
    jsr set_vram_addrs

    ldx #7
xloop:
    lda #(COLOR::RED << 4)  ; background color
    sta VERA::DATA1
    dex
    bne xloop

    inc ycoord
    lda ycoord
    cmp yend
    bne yloop

    ; draw score label
    lda #BOARD_XMIN + 33
    sta xcoord
    lda #BOARD_YMIN + 2
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::YELLOW)
    sta color
    lda #<score_str
    sta copy_ram_ptr
    lda #>score_str
    sta copy_ram_ptr+1
    jsr draw_diagonal_string

    ; draw score value
    jsr draw_score

    ; draw ships label
    lda #BOARD_XMIN + 33
    sta xcoord
    lda #BOARD_YMIN + 10
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::GREEN)
    sta color
    lda #<ships_str
    sta copy_ram_ptr
    lda #>ships_str
    sta copy_ram_ptr+1
    jsr draw_string

    ; draw ships value
    jsr draw_ships

    ; draw level label
    lda #BOARD_XMIN + 33
    sta xcoord
    lda #BOARD_YMIN + 13
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::PURPLE)
    sta color
    lda #<level_str
    sta copy_ram_ptr
    lda #>level_str
    sta copy_ram_ptr+1
    jsr draw_string

    ; draw level value
    jsr draw_level_number

    ; draw hiscore label
    lda #BOARD_XMIN + 32
    sta xcoord
    lda #BOARD_YMIN + 15
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::WHITE)
    sta color
    lda #<hiscore_str
    sta copy_ram_ptr
    lda #>hiscore_str
    sta copy_ram_ptr+1
    jsr draw_diagonal_string

    ; draw hiscore value
    jmp draw_hiscore

.endproc

.proc draw_level_blocks

    ; compute glyph offset into X register: (level % 5) * 4
    ; (level is never higher than 9, so no loop is necessary)
    lda level
    cmp #5
    bcc mod_5_done
    sbc #5
mod_5_done:
    asl
    asl
    tax

    ; set level block glyphs
    lda level_glyphs,x
    sta glyphs
    inx
    lda level_glyphs,x
    sta glyphs+1
    inx
    lda level_glyphs,x
    sta glyphs+2
    inx
    lda level_glyphs,x
    sta glyphs+3

    ; set color
    ldx level
    lda level_color,x
    sta color

    ; set grid parameters
    lda #BOARD_XMIN + 3
    sta xbegin
    lda #BOARD_YMIN + 3
    sta ybegin
    lda #BOARD_XMIN + (3+7*4)
    sta xend
    lda #BOARD_YMIN + (3+5*4)
    sta yend

    jmp draw_block_grid

.endproc

; draw a 2x2 tile block
;
; glyphs - glyphs to use for block
; xcoord - top-left column
; ycoord - top-left row
; color - color of block
.proc draw_block

    ; get address of top-left tile
    jsr coords_to_vram_addr

    ; set vram pointers
    jsr set_vram_addrs

    ; set glyph for top-left and top-right
    ldx #0
    lda glyphs,x
    sta VERA::DATA0
    inx
    lda glyphs,x
    sta VERA::DATA0

    ; set color for top-left and top-right
    lda color
    sta VERA::DATA1
    sta VERA::DATA1

    ; add 64*2 (one line) to vram_addr
    clc
    lda vram_addr
    adc #(64*2)
    sta vram_addr
    lda vram_addr+1
    adc #0
    sta vram_addr+1
    lda vram_addr+2
    adc #0
    sta vram_addr+2

    ; set vram pointers
    jsr set_vram_addrs

    ; set glyph for bottom-left and bottom-right
    ldx #2
    lda glyphs,x
    sta VERA::DATA0
    inx
    lda glyphs,x
    sta VERA::DATA0

    ; set color for bottom-left and bottom-right
    lda color
    sta VERA::DATA1
    sta VERA::DATA1

    rts

.endproc

; draw a horizontal line of blocks with a 4-tile stride
;
; glyphs - glyphs to use for block
; color - color of block
; xbegin - first xcoord
; xend - last xcoord + 4
; ycoord - top-left row
.proc draw_block_line

    lda xbegin
    sta xcoord

loop:

    jsr draw_block

    lda xcoord
    clc
    adc #4
    sta xcoord
    cmp xend
    bne loop

    rts

.endproc

; draw a grid of blocks with a 4-tile stride
;
; glyphs - glyphs to use for block
; color - color of block
; xbegin - first xcoord
; xend - last xcoord + 4
; ybegin - first ycoord
; yend - last ycoord + 4
.proc draw_block_grid

    lda ybegin
    sta ycoord

loop:

    jsr draw_block_line

    lda ycoord
    clc
    adc #4
    sta ycoord
    cmp yend
    bne loop

    rts

.endproc
