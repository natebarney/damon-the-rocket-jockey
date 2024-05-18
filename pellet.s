.include "color.inc"
.include "graphics.inc"
.include "level.inc"
.include "mobile.inc"
.include "pellet.inc"
.include "player.inc"
.include "ship.inc"
.include "tiledata.inc"
.include "vera.inc"

.data

pellet_map: .res 9
active_pellets: .res 1

pellet_xidx: .res 1
pellet_yidx: .res 1

.code

.proc init_pellet_map

    lda #%00111111
    sta pellet_map
    sta pellet_map+2
    sta pellet_map+4
    sta pellet_map+6
    sta pellet_map+8

    lda #%01111111
    sta pellet_map+1
    sta pellet_map+3
    sta pellet_map+5
    sta pellet_map+7

    lda #58
    sta active_pellets

    rts

.endproc

.proc draw_pellets

    ; set pellet block glyphs
    ldx #TILE::PELLET_TOP_LEFT
    stx glyphs
    inx
    stx glyphs+1
    inx
    stx glyphs+2
    inx
    stx glyphs+3

    ; set color
    lda #COLOR::CYAN
    sta color

    ; set grid parameters for between horizontal blocks
    lda #BOARD_XMIN + 5
    sta xbegin
    lda #BOARD_XMIN + (5+6*4)
    sta xend
    lda #BOARD_YMIN + 3
    sta ybegin
    lda #BOARD_YMIN + (3+5*4)
    sta yend

    jsr draw_block_grid

    ; set grid parameters for between vertical blocks
    lda #BOARD_XMIN + 3
    sta xbegin
    lda #BOARD_XMIN + (3+7*4)
    sta xend
    lda #BOARD_YMIN + 5
    sta ybegin
    lda #BOARD_YMIN + (5+4*4)
    sta yend

    jmp draw_block_grid

.endproc

.proc get_pellet_indices

    ; no pellets against vertical walls
    lda player_data + MOBILE::xpos
    cmp #SHIP_XMIN
    beq no_pellet
    cmp #SHIP_XMAX
    beq no_pellet

    ; no pellets against horizontal walls
    lda player_data + MOBILE::ypos
    cmp #SHIP_YMIN
    beq no_pellet
    cmp #SHIP_YMAX
    beq no_pellet

    ; store default pellet X offset
    sec
    lda player_data + MOBILE::xpos
    sbc #(SHIP_XMIN + BLOCK_SIZE)
    sta pellet_xidx

    ; store default pellet Y offset
    sec
    lda player_data + MOBILE::ypos
    sbc #(SHIP_YMIN + BLOCK_SIZE)
    sta pellet_yidx

    ; dispatch based on facing
    lda player_data + MOBILE::dir
    cmp #DIR::RIGHT
    beq facing_right
    cmp #DIR::LEFT
    beq facing_left
    cmp #DIR::DOWN
    beq facing_down
    bra facing_up

facing_right:
    ; if facing right, relevant coordinate is x,
    ; but ship's nose is one block further
    sec
    lda player_data + MOBILE::xpos
    sbc #(SHIP_XMIN + BLOCK_SIZE / 2)
    sta pellet_xidx
    bra check_pellet

facing_left:
    ; if facing left, relevant coordinate is x
    sec
    lda player_data + MOBILE::xpos
    sbc #(SHIP_XMIN + BLOCK_SIZE + BLOCK_SIZE / 2)
    sta pellet_xidx
    bra check_pellet

facing_down:
    ; if facing down, relevant coordinate is y,
    ; but ship's nose is one block further
    sec
    lda player_data + MOBILE::ypos
    sbc #(SHIP_YMIN + BLOCK_SIZE / 2)
    sta pellet_yidx
    bra check_pellet

facing_up:
    ; if facing up, relevant coordinate is y
    sec
    lda player_data + MOBILE::ypos
    sbc #(SHIP_YMIN + BLOCK_SIZE + BLOCK_SIZE / 2)
    sta pellet_yidx

check_pellet:
    ; pellets are aligned to 32 pixels in the relevant dimension,
    ; so if the 5 low bits are clear, we're at a pellet
    and #%00011111
    beq found_pellet

no_pellet:
    ; return false
    lda #0
    rts

found_pellet:
    ; divide pellet_xidx by 32 to get horizontal index
    lda pellet_xidx
    lsr
    lsr
    lsr
    lsr
    lsr
    sta pellet_xidx

    ; divide pellet_yidx by 16 to get vertical index
    lda pellet_yidx
    lsr
    lsr
    lsr
    lsr
    sta pellet_yidx

    ; return true
    lda #$ff
    rts

.endproc

.proc does_pellet_exist

    jsr get_pellet_mask
    ldy pellet_yidx
    and pellet_map,y
    rts

.endproc

.proc mark_pellet_gone

    jsr get_pellet_mask
    eor #$ff
    ldy pellet_yidx
    and pellet_map,y
    sta pellet_map,y
    dec active_pellets
    rts

.endproc

.proc blank_pellet

    ; set blank block glyphs
    lda #' '
    sta glyphs
    sta glyphs+1
    sta glyphs+2
    sta glyphs+3

    ; set color
    lda #COLOR::CYAN
    sta color

    ; compute x coordinate
    lda pellet_xidx
    asl
    asl
    clc
    adc #BOARD_XMIN + 3
    sta xcoord

    ; offset x coordinate on even rows
    lda pellet_yidx
    and #%00000001
    bne no_xinc
    inc xcoord
    inc xcoord
no_xinc:

    ; compute y coordinate
    lda pellet_yidx
    asl
    clc
    adc #BOARD_YMIN + 3
    sta ycoord

    jmp draw_block

.endproc

.proc get_pellet_mask

    lda #1

    ldx pellet_xidx
    beq done
loop:
    asl
    dex
    bne loop

done:
    rts

.endproc
