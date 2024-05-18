.include "mobile.inc"
.include "sprite.inc"

.zeropage

mobile_data: .res 2
mobile_ro_data: .res 2

.data

boundary: .res 1

.code

.proc update_mobile_position

    ; add x velocity to position
    clc
    ldy #MOBILE::xvel
    lda (mobile_data),y
    ldy #MOBILE::xpos
    adc (mobile_data),y
    sta (mobile_data),y

    ; add y velocity to position
    clc
    ldy #MOBILE::yvel
    lda (mobile_data),y
    ldy #MOBILE::ypos
    adc (mobile_data),y
    sta (mobile_data),y

    stz boundary

check_xmin:
    ldy #MOBILE_RO::xmin
    lda (mobile_ro_data),y
    ldy #MOBILE::xpos
    cmp (mobile_data),y
    bcc check_xmax
    sta (mobile_data),y
    ldy #MOBILE::xvel
    lda #0
    sta (mobile_data),y
    lda #BOUNDARY::XMIN
    sta boundary
    bra check_ymin

check_xmax:
    ldy #MOBILE::xpos
    lda (mobile_data),y
    ldy #MOBILE_RO::xmax
    cmp (mobile_ro_data),y
    bcc check_ymin
    lda (mobile_ro_data),y
    ldy #MOBILE::xpos
    sta (mobile_data),y
    ldy #MOBILE::xvel
    lda #0
    sta (mobile_data),y
    lda boundary
    ora #BOUNDARY::XMAX
    sta boundary

check_ymin:
    ldy #MOBILE_RO::ymin
    lda (mobile_ro_data),y
    ldy #MOBILE::ypos
    cmp (mobile_data),y
    bcc check_ymax
    sta (mobile_data),y
    ldy #MOBILE::yvel
    lda #0
    sta (mobile_data),y
    lda boundary
    ora #BOUNDARY::YMIN
    sta boundary
    bra set_pos

check_ymax:
    ldy #MOBILE::ypos
    lda (mobile_data),y
    ldy #MOBILE_RO::ymax
    cmp (mobile_ro_data),y
    bcc set_pos
    lda (mobile_ro_data),y
    ldy #MOBILE::ypos
    sta (mobile_data),y
    ldy #MOBILE::yvel
    lda #0
    sta (mobile_data),y
    lda boundary
    ora #BOUNDARY::YMAX
    sta boundary

set_pos:
    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y
    pha
    ldy #MOBILE::xpos
    lda (mobile_data),y
    tax
    ldy #MOBILE::ypos
    lda (mobile_data),y
    tay
    pla
    jsr set_sprite_pos
    lda boundary
    rts

.endproc

.proc set_mobile_facing

    ldy #MOBILE::dir
    lda (mobile_data),y
    pha
    bit #(DIR::DOWN | DIR::UP)
    bne vertical

    ldy #MOBILE_RO::horiz_ptr
    lda (mobile_ro_data),y
    sta sprite_data_ptr
    iny
    lda (mobile_ro_data),y
    sta sprite_data_ptr+1
    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y
    bra set_image

vertical:
    ldy #MOBILE_RO::vert_ptr
    lda (mobile_ro_data),y
    sta sprite_data_ptr
    iny
    lda (mobile_ro_data),y
    sta sprite_data_ptr+1
    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y

set_image:
    jsr set_sprite_image

    pla
    bit #(DIR::DOWN | DIR::RIGHT)
    beq no_flip
    ldx #1
    ldy #1
    bra set_flip
no_flip:
    ldx #0
    ldy #0

set_flip:
    phy
    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y
    ply
    jmp set_sprite_flip

.endproc

.proc get_cw_direction

    cmp #DIR::RIGHT
    bne not_right
    lda #DIR::DOWN
    rts
not_right:

    cmp #DIR::DOWN
    bne not_down
    lda #DIR::LEFT
    rts
not_down:

    cmp #DIR::LEFT
    bne not_left
    lda #DIR::UP
    rts
not_left:

    cmp #DIR::UP
    bne not_up
    lda #DIR::RIGHT
    rts
not_up:

    rts

.endproc

.proc get_ccw_direction

    cmp #DIR::RIGHT
    bne not_right
    lda #DIR::UP
    rts
not_right:

    cmp #DIR::UP
    bne not_up
    lda #DIR::LEFT
    rts
not_up:

    cmp #DIR::LEFT
    bne not_left
    lda #DIR::DOWN
    rts
not_left:

    cmp #DIR::DOWN
    bne not_down
    lda #DIR::RIGHT
    rts
not_down:

    rts

.endproc

.proc get_reverse_direction

    cmp #DIR::RIGHT
    bne not_right
    lda #DIR::LEFT
    rts
not_right:

    cmp #DIR::LEFT
    bne not_left
    lda #DIR::RIGHT
    rts
not_left:

    cmp #DIR::DOWN
    bne not_down
    lda #DIR::UP
    rts
not_down:

    cmp #DIR::UP
    bne not_up
    lda #DIR::DOWN
    rts
not_up:

    rts

.endproc
