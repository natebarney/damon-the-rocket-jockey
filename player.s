.include "animation.inc"
.include "collision.inc"
.include "input.inc"
.include "mobile.inc"
.include "player.inc"
.include "ship.inc"
.include "sprite.inc"

PLAYER_XSTART = SHIP_XMAX
PLAYER_YSTART = SHIP_YMAX

.data

player_anim: .tag ANIM_DATA
player_data: .tag MOBILE

.code

.proc spawn_player

    lda #<player_data
    sta mobile_data
    lda #>player_data
    sta mobile_data+1
    lda #<player_ro_data
    sta mobile_ro_data
    lda #>player_ro_data
    sta mobile_ro_data+1

    lda #PLAYER_STATE::ALIVE
    sta player_data + MOBILE::state

    stz player_data + MOBILE::xvel
    stz player_data + MOBILE::yvel

    lda #PLAYER_XSTART
    sta player_data + MOBILE::xpos
    lda #PLAYER_YSTART
    sta player_data + MOBILE::ypos
    jsr update_mobile_position

    lda #DIR::NONE
    sta player_data + MOBILE::dir
    jsr set_mobile_facing

    lda player_ro_data + MOBILE_RO::sprite
    ldx player_ro_data + MOBILE_RO::collmask
    jsr set_sprite_collision_mask

    lda player_ro_data + MOBILE_RO::sprite
    ldx #SPRITE_SIZE::W_16
    ldy #SPRITE_SIZE::H_16
    jsr set_sprite_size

    lda player_ro_data + MOBILE_RO::sprite
    sta player_anim + ANIM_DATA::sprite
    jmp sprite_enable

.endproc

.proc kill_player

    lda #PLAYER_STATE::DEAD
    sta player_data + MOBILE::state

    lda #<player_death_animation
    sta player_anim + ANIM_DATA::table
    lda #>player_death_animation
    sta player_anim + ANIM_DATA::table + 1

    stz player_anim + ANIM_DATA::delay
    rts

.endproc

.proc update_player

    lda player_data + MOBILE::state
    cmp #PLAYER_STATE::ALIVE
    beq alive
    cmp #PLAYER_STATE::DEAD
    beq dead
    rts

dead:
    lda #<player_anim
    sta animation_data_ptr
    lda #>player_anim
    sta animation_data_ptr + 1
    jsr update_animation
    beq still_dead
    lda #PLAYER_STATE::RESPAWNING
    sta player_data + MOBILE::state
still_dead:
    rts

alive:
    lda sprite_collisions
    bit #COLL_MASK::PLAYER
    beq update_pos
    jsr check_player_enemy_collision

update_pos:
    lda #<player_data
    sta mobile_data
    lda #>player_data
    sta mobile_data+1
    lda #<player_ro_data
    sta mobile_ro_data
    lda #>player_ro_data
    sta mobile_ro_data+1
    jmp update_ship_position

.endproc

.proc handle_steering

check_right:
    lda current_input
    and #INPUT::RIGHT
    beq check_left
    jsr can_turn_right
    beq check_left
    lda #SHIP_VEL_POS
    sta player_data + MOBILE::xvel
    stz player_data + MOBILE::yvel
    ldx #DIR::RIGHT
    bra complete_turn

check_left:
    lda current_input
    and #INPUT::LEFT
    beq check_down
    jsr can_turn_left
    beq check_down
    lda #SHIP_VEL_NEG
    sta player_data + MOBILE::xvel
    stz player_data + MOBILE::yvel
    ldx #DIR::LEFT
    bra complete_turn

check_down:
    lda current_input
    and #INPUT::DOWN
    beq check_up
    jsr can_turn_down
    beq check_up
    lda #SHIP_VEL_POS
    sta player_data + MOBILE::yvel
    stz player_data + MOBILE::xvel
    ldx #DIR::DOWN
    bra complete_turn

check_up:
    lda current_input
    and #INPUT::UP
    beq done
    jsr can_turn_up
    beq done
    lda #SHIP_VEL_NEG
    sta player_data + MOBILE::yvel
    stz player_data + MOBILE::xvel
    ldx #DIR::UP

complete_turn:
    ; set facing
    stx player_data + MOBILE::dir
    lda #<player_data
    sta mobile_data
    lda #>player_data
    sta mobile_data+1
    lda #<player_ro_data
    sta mobile_ro_data
    lda #>player_ro_data
    sta mobile_ro_data+1
    jsr set_mobile_facing

    ; clear last turn
    jmp clear_steering_input

done:
    rts

.endproc

.proc can_turn_left

    ; if the player is facing left, return false
    lda player_data + MOBILE::dir
    cmp #DIR::LEFT
    beq false

    ; if the player is at the left wall, return false
    lda player_ro_data + MOBILE_RO::xmin
    cmp player_data + MOBILE::xpos
    bcs false

    ; check if we're on a row that allows travel
    jmp can_turn_horizontal

false:
    lda #0
    rts

.endproc

.proc can_turn_right

    ; if the player is facing right, return false
    lda player_data + MOBILE::dir
    cmp #DIR::RIGHT
    beq false

    ; if the player is at the right wall, return false
    lda player_data + MOBILE::xpos
    cmp player_ro_data + MOBILE_RO::xmax
    bcs false

    ; check if we're on a row that allows travel
    jmp can_turn_horizontal

false:
    lda #0
    rts

.endproc

.proc can_turn_horizontal

    ; if the player is between blocks, or at an odd block, return false
    sec
    lda player_data + MOBILE::ypos
    sbc player_ro_data + MOBILE_RO::ymin
    and #$1f            ; if the low nibble is nonzero, we're between blocks
    bne false           ; if bit 5 is set, we're on an odd block

    ; passed all checks, return true
    lda #$ff
    rts

false:
    lda #0
    rts

.endproc

.proc can_turn_up

    ; if the player is facing up, return false
    lda player_data + MOBILE::dir
    cmp #DIR::UP
    beq false

    ; if the player is at the top wall, return false
    lda player_ro_data + MOBILE_RO::ymin
    cmp player_data + MOBILE::ypos
    bcs false

    ; check if we're on a column that allows travel
    jmp can_turn_vertical

false:
    lda #0
    rts

.endproc

.proc can_turn_down

    ; if the player is facing down, return false
    lda player_data + MOBILE::dir
    cmp #DIR::DOWN
    beq false

    ; if the player is at the bottom wall, return false
    lda player_data + MOBILE::ypos
    cmp player_ro_data + MOBILE_RO::ymax
    bcs false

    ; check if we're on a column that allows travel
    jmp can_turn_vertical

false:
    lda #0
    rts

.endproc

.proc can_turn_vertical

    ; if the player is between blocks, or at an odd block, return false
    sec
    lda player_data + MOBILE::xpos
    sbc player_ro_data + MOBILE_RO::xmin
    and #$1f            ; if the low nibble is nonzero, we're between blocks
    bne false           ; if bit 5 is set, we're on an odd block

    ; passed all checks, return true
    lda #$ff
    rts

false:
    lda #0
    rts

.endproc

.proc load_player_rect

    ; set x extents to full sprite size
    lda player_data + MOBILE::xpos
    sta other_rect + RECT::xmin
    clc
    adc #SHIP_SIZE
    sta other_rect + RECT::xmax

    ; set y extents to full sprite size
    lda player_data + MOBILE::ypos
    sta other_rect + RECT::ymin
    clc
    adc #SHIP_SIZE
    sta other_rect + RECT::ymax

    ; check to see which direction sprite is facing
    ldy #MOBILE::dir
    lda (mobile_data),y
    cmp #DIR::RIGHT
    beq facing_right
    cmp #DIR::UP
    beq facing_up
    cmp #DIR::DOWN
    beq facing_down

    ; bring xmax in 4 pixels to exclude tail fins
facing_left:
    lda other_rect + RECT::xmax
    sec
    sbc #4
    sta other_rect + RECT::xmax
    bra horizontal

    ; bring xmin in 4 pixels to exclude tail fins
facing_right:
    lda other_rect + RECT::xmin
    clc
    adc #4
    sta other_rect + RECT::xmin
    bra horizontal

    ; bring ymax in 4 pixels to exclude tail fins
facing_up:
    lda other_rect + RECT::ymax
    sec
    sbc #4
    sta other_rect + RECT::ymax
    bra vertical

    ; bring ymin in 4 pixels to exclude tail fins
facing_down:
    lda other_rect + RECT::ymin
    clc
    adc #4
    sta other_rect + RECT::ymin

    ; vertical - bring x extents in 3 pixels on each side
vertical:
    lda other_rect + RECT::xmin
    clc
    adc #3
    sta other_rect + RECT::xmin
    lda other_rect + RECT::xmax
    sec
    sbc #3
    sta other_rect + RECT::xmax
    rts

    ; horizontal - bring y extents in 3 pixels on each side
horizontal:
    lda other_rect + RECT::ymin
    clc
    adc #3
    sta other_rect + RECT::ymin
    lda other_rect + RECT::ymax
    sec
    sbc #3
    sta other_rect + RECT::ymax
    rts

.endproc

.proc check_player_enemy_collision

    jsr load_player_rect
    jsr check_enemy_collision
    bne hit
    rts

hit:
    lda #PLAYER_STATE::DYING
    sta player_data + MOBILE::state
    lda #$ff
    rts

.endproc

.rodata

player_ro_data:
.byte $00                                           ; sprite
.byte $00                                           ; palette
.word PLAYER_H_SPRITE_PTR                           ; horiz_ptr
.word PLAYER_V_SPRITE_PTR                           ; vert_ptr
.byte SHIP_XMIN                                     ; xmin
.byte SHIP_XMAX                                     ; xmax
.byte SHIP_YMIN                                     ; ymin
.byte SHIP_YMAX                                     ; ymax
.byte COLL_MASK::PLAYER | COLL_MASK::ENEMY_BULLET   ; collmask

player_death_animation:

.byte ANIM_CMD::COLL_MASK, 0
.byte ANIM_CMD::SIZE, SPRITE_SIZE::W_32, SPRITE_SIZE::H_32
.byte ANIM_CMD::FLIP, 0, 0
.byte ANIM_CMD::RELPOS, <(-4), <(-2)
.byte ANIM_CMD::IMAGE
.word EXPLOSION_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, 5
.byte ANIM_CMD::IMAGE
.word EXPLOSION_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, 5
.byte ANIM_CMD::IMAGE
.word EXPLOSION_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, 5
.byte ANIM_CMD::DISABLE
.byte ANIM_CMD::DELAY, 60
.byte ANIM_CMD::IMAGE
.word SKULL_1_SPRITE_PTR
.byte ANIM_CMD::ENABLE
.byte ANIM_CMD::DELAY, 90
.byte ANIM_CMD::IMAGE
.word SKULL_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, 10
.byte ANIM_CMD::IMAGE
.word SKULL_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, 10
.byte ANIM_CMD::IMAGE
.word SKULL_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, 10
.byte ANIM_CMD::IMAGE
.word SKULL_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, 60
.byte ANIM_CMD::DISABLE
.byte ANIM_CMD::STOP
