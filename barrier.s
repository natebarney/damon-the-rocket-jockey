.include "barrier.inc"
.include "color.inc"
.include "graphics.inc"
.include "level.inc"
.include "mobile.inc"
.include "pellet.inc"
.include "score.inc"
.include "tiledata.inc"
.include "vera.inc"

.zeropage

barriers_ptr: .res 2

.data

mobile_coord: .res 1

.code

.proc draw_barriers

    ; populate barriers_ptr based on current level
    lda level
    asl
    tay
    lda level_barriers,y
    sta barriers_ptr
    iny
    lda level_barriers,y
    sta barriers_ptr+1

    ; set tile glyphs
    lda #TILE::BARRIER
    sta glyphs
    sta glyphs+1
    sta glyphs+2
    sta glyphs+3

    ; set color
    lda #COLOR::L_GREY
    sta color

    ; draw barriers
    ldy #0
loop:
    lda (barriers_ptr),y
    cmp #$ff
    beq done
    phy
    jsr draw_barrier
    ply
    iny
    dec active_pellets
    bra loop

done:
    rts

.endproc

.proc draw_barrier

    ; calculate top-left tile y coordinate
    pha
    and #$0f            ; mask off high nibble
    asl                 ; multiply by 2 (tiles per block)
    sec                 ; add 1 tile for border
    adc #BOARD_YMIN     ; add BOARD_YMIN tiles
    sta ycoord
    pla

    ; calculate top-left tile x coordinate
    and #$f0            ; mask off low nibble
    lsr                 ; shift high nibble to low nibble
    lsr                 ;   but only do 3 shifts instead of 4, to
    lsr                 ;   multiply by 2 (tiles per block)
    sec                 ; add 1 tile for border
    adc #BOARD_XMIN     ; add BOARD_XMIN tiles
    sta xcoord

    jmp draw_block

.endproc

.proc is_mobile_facing_barrier

    ; get mobile x coord in blocks into high nibble
    ldy #MOBILE::xpos
    lda (mobile_data),y
    ldy #MOBILE_RO::xmin
    sec
    sbc (mobile_ro_data),y
    bit #$0f
    bne false
    and #$f0
    sta mobile_coord

    ; get mobile y coord in blocks into low nibble
    ldy #MOBILE::ypos
    lda (mobile_data),y
    ldy #MOBILE_RO::ymin
    sec
    sbc (mobile_ro_data),y
    bit #$0f
    bne false
    lsr
    lsr
    lsr
    lsr
    ora mobile_coord
    sta mobile_coord

    ; check facing direction for coordinate adjustment
    ldy #MOBILE::dir
    lda (mobile_data),y
    cmp #DIR::RIGHT
    beq facing_right
    cmp #DIR::LEFT
    beq facing_left
    cmp #DIR::DOWN
    beq facing_down
    cmp #DIR::UP
    beq facing_up
    bne false

facing_right:
    clc
    lda mobile_coord
    adc #$10            ; add 1 to x coord (high nibble)
    sta mobile_coord
    bra check_barriers

facing_left:
    sec
    lda mobile_coord
    sbc #$10            ; subtract 1 from x coord (high nibble)
    sta mobile_coord
    bra check_barriers

facing_down:
    clc
    lda mobile_coord
    adc #$01            ; add 1 to y coord (low nibble)
    sta mobile_coord
    bra check_barriers

facing_up:
    sec
    lda mobile_coord
    sbc #$01            ; subtract 1 from y coord (low nibble)
    sta mobile_coord

check_barriers:
    ldy #0
loop:
    lda (barriers_ptr),y
    cmp #$ff
    beq false
    cmp mobile_coord
    beq true
    iny
    bra loop

false:
    lda #0
    rts

true:
    lda #$ff
    rts

.endproc

.rodata

level1_barriers: .byte $ff
level2_barriers: .byte $72, $65, $85, $78, $ff
level3_barriers: .byte $43, $a3, $47, $a7, $ff
level4_barriers: .byte $63, $83, $67, $87, $ff
level5_barriers: .byte $32, $b2, $38, $b8, $ff
level6_barriers: .byte $25, $45, $a5, $c5, $ff
level7_barriers: .byte $72, $65, $85, $78, $43, $a3, $47, $a7, $ff
level8_barriers: .byte $43, $a3, $47, $a7, $63, $83, $67, $87, $ff
level9_barriers: .byte $63, $83, $67, $87, $32, $b2, $38, $b8, $ff
level10_barriers: .byte $32, $b2, $38, $b8, $25, $45, $a5, $c5, $ff

level_barriers:
.addr level1_barriers
.addr level2_barriers
.addr level3_barriers
.addr level4_barriers
.addr level5_barriers
.addr level6_barriers
.addr level7_barriers
.addr level8_barriers
.addr level9_barriers
.addr level10_barriers
