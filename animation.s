.include "animation.inc"
.include "sprite.inc"

.zeropage

animation_data_ptr: .res 2
animation_table: .res 2

.data

handler: .res 2
sprite_tmp_xpos: .res 1
sprite_tmp_ypos: .res 1
animation_complete: .res 1

.code

.proc update_animation

    stz animation_complete

    ; check if we're in a delay
    ldy #ANIM_DATA::delay
    lda (animation_data_ptr),y
    beq init_ptr
    dec a
    sta (animation_data_ptr),y
    beq init_ptr
    lda #0  ; return 0 because animation is not complete
    rts

    ; copy animation table pointer to animation_table
init_ptr:
    ldy #ANIM_DATA::table
    lda (animation_data_ptr),y
    sta animation_table
    iny
    lda (animation_data_ptr),y
    sta animation_table+1

    ; get the next command
read_cmd:
    ldy #0
    lda (animation_table),y
    iny

    ; call handler
    ;
    ; handler returns number of bytes to advance table pointer in Y, and
    ; sets the carry flag if the processing loop should continue for this
    ; frame
    asl                 ; multiply the command enum value by 2
    tax                 ; use this value as an offset into the jump table
    lda jump_table,x    ; load the low byte of the handler's address
    sta handler         ; store the low byte of the handler's address
    inx
    lda jump_table,x    ; load the high byte of the handler's address
    sta handler+1       ; store the high byte of the handler's address
    jsr invoke_handler  ; this routine does an indirect jump, so the selected
                        ; handler will return here

    ; advance animation_table and loop if needed
    php                     ; save carry flag returned from invoke_handler
    clc
    tya                     ; add Y to animation_table
    adc animation_table
    sta animation_table
    lda animation_table+1
    adc #0
    sta animation_table+1
    plp                     ; restore saved carry flag
    bcs read_cmd            ; loop if carry flag is set

    ; we're done for this frame, so update animation table pointer in the struct
    ldy #ANIM_DATA::table
    lda animation_table
    sta (animation_data_ptr),y
    iny
    lda animation_table+1
    sta (animation_data_ptr),y

    ; return nonzero if animation is complete
    lda animation_complete
    rts

.endproc

.proc invoke_handler

    jmp (handler)

.endproc

.proc handle_stop

    inc animation_complete
    dey ; keep instruction pointer pointing at STOP instruction

    ; intentional fall-through to handle_break

.endproc

.proc handle_break

    clc
    rts

.endproc

.proc handle_jump

    ; get low byte of destination
    lda (animation_table),y
    tax

    ; get high byte of destination
    iny
    lda (animation_table),y

    ; store destination in instruction pointer
    stx animation_table
    sta animation_table+1

    ldy #0
    sec
    rts

.endproc

.proc handle_delay

    ; get delay parameter
    lda (animation_table),y

    ; store delay in variable
    php
    ldy #ANIM_DATA::delay
    sta (animation_data_ptr),y
    ldy #2
    plp

    ; if delay is zero, set carry flag, otherwise clear it
    beq set_carry
    clc
    rts
set_carry:
    sec
    rts

.endproc

.proc handle_enable

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    jsr sprite_enable

    ldy #1
    sec
    rts

.endproc

.proc handle_disable

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    jsr sprite_disable

    ldy #1
    sec
    rts

.endproc

.proc handle_image

    lda (animation_table),y
    sta sprite_data_ptr
    iny
    lda (animation_table),y
    sta sprite_data_ptr+1

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    jsr set_sprite_image

    ldy #3
    sec
    rts

.endproc

.proc handle_size

    lda (animation_table),y
    tax
    iny
    lda (animation_table),y
    pha

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    ply
    jsr set_sprite_size

    ldy #3
    sec
    rts

.endproc

.proc handle_pos

    lda (animation_table),y
    tax
    iny
    lda (animation_table),y
    pha

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    ply
    jsr set_sprite_pos

    ldy #3
    sec
    rts

.endproc

.proc handle_relpos

    ; get offsets
    lda (animation_table),y
    sta sprite_tmp_xpos
    iny
    lda (animation_table),y
    sta sprite_tmp_ypos

    ; get current sprite position
    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    pha
    jsr get_sprite_pos

    ; compute new x position
    clc
    txa
    adc sprite_tmp_xpos
    tax

    ; compute new y position
    clc
    tya
    adc sprite_tmp_ypos
    tay

    ; set sprite position
    pla
    jsr set_sprite_pos

    ldy #3
    sec
    rts

.endproc

.proc handle_flip

    lda (animation_table),y
    tax
    iny
    lda (animation_table),y
    pha

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    ply
    jsr set_sprite_flip

    ldy #3
    sec
    rts

.endproc

.proc handle_palette

    lda (animation_table),y
    tax

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    jsr set_sprite_palette_offset

    ldy #2
    sec
    rts

.endproc

.proc handle_coll_mask

    lda (animation_table),y
    tax

    ldy #ANIM_DATA::sprite
    lda (animation_data_ptr),y
    jsr set_sprite_collision_mask

    ldy #2
    sec
    rts

.endproc

.rodata

jump_table:

.addr handle_stop
.addr handle_break
.addr handle_jump
.addr handle_delay
.addr handle_enable
.addr handle_disable
.addr handle_image
.addr handle_size
.addr handle_pos
.addr handle_relpos
.addr handle_flip
.addr handle_palette
.addr handle_coll_mask
