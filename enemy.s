.include "animation.inc"
.include "barrier.inc"
.include "bullet.inc"
.include "collision.inc"
.include "enemy.inc"
.include "kernal.inc"
.include "level.inc"
.include "mobile.inc"
.include "pellet.inc"
.include "player.inc"
.include "score.inc"
.include "ship.inc"
.include "sound.inc"
.include "sprite.inc"
.include "vera.inc"

ENEMY0_XSTART = SHIP_XMIN + 2 * BLOCK_SIZE
ENEMY_YSTART = SHIP_YMIN + 0 * BLOCK_SIZE

ENEMY_EXPLOSION_FRAMES = 5
ENEMY_FIRE_DELAY = 24

.struct ENEMY
    mobile      .tag MOBILE
    fire_delay  .byte
.endstruct

.data

enemy_data:
    .tag ENEMY
    .tag ENEMY
    .tag ENEMY
    .tag ENEMY
    .tag ENEMY

enemy_anim:
    .tag ANIM_DATA
    .tag ANIM_DATA
    .tag ANIM_DATA
    .tag ANIM_DATA
    .tag ANIM_DATA

active_enemies: .res 1
enemy_xstart: .res 1

.code

.proc select_first_enemy

    lda #<enemy_anim
    sta animation_data_ptr
    lda #>enemy_anim
    sta animation_data_ptr+1

    lda #<enemy_data
    sta mobile_data
    lda #>enemy_data
    sta mobile_data+1

    lda #<enemy_ro_data
    sta mobile_ro_data
    lda #>enemy_ro_data
    sta mobile_ro_data+1

    lda #ENEMY0_XSTART
    sta enemy_xstart

    rts

.endproc

.proc select_next_enemy

    clc
    lda animation_data_ptr
    adc #.sizeof(ANIM_DATA)
    sta animation_data_ptr
    lda animation_data_ptr+1
    adc #0
    sta animation_data_ptr+1

    clc
    lda mobile_data
    adc #.sizeof(ENEMY)
    sta mobile_data
    lda mobile_data+1
    adc #0
    sta mobile_data+1

    clc
    lda mobile_ro_data
    adc #.sizeof(MOBILE_RO)
    sta mobile_ro_data
    lda mobile_ro_data+1
    adc #0
    sta mobile_ro_data+1

    clc
    lda enemy_xstart
    adc #(2 * BLOCK_SIZE)
    sta enemy_xstart

    rts

.endproc

.proc load_enemy_rect

    ; set x extents to full sprite size
    ldy #MOBILE::xpos
    lda (mobile_data),y
    sta enemy_rect + RECT::xmin
    clc
    adc #SHIP_SIZE
    sta enemy_rect + RECT::xmax

    ; set y extents to full sprite size
    ldy #MOBILE::ypos
    lda (mobile_data),y
    sta enemy_rect + RECT::ymin
    clc
    adc #SHIP_SIZE
    sta enemy_rect + RECT::ymax

    ; check to see whether the sprite is horizontal or vertical
    ldy #MOBILE::dir
    lda (mobile_data),y
    cmp #DIR::DOWN
    beq vertical
    cmp #DIR::UP
    beq vertical

    ; horizontal - bring y extents in 1 pixel on each side
    inc enemy_rect + RECT::ymin
    dec enemy_rect + RECT::ymax
    rts

    ; vertical - bring x extents in 1 pixel on each side
vertical:
    inc enemy_rect + RECT::xmin
    dec enemy_rect + RECT::xmax
    rts

.endproc

.proc init_enemies

    jsr select_first_enemy

    ldx level_enemies
    stx active_enemies
loop:
    phx
    jsr init_enemy
    jsr select_next_enemy
    plx
    dex
    bne loop

    rts

.endproc

.proc reset_enemies

    jsr select_first_enemy

    ldx level_enemies
loop:
    phx
    jsr reset_enemy
    jsr select_next_enemy
    plx
    dex
    bne loop

    rts

.endproc

.proc init_enemy

    lda #ENEMY_STATE::UTURNING
    ldy #MOBILE::state
    sta (mobile_data),y
    rts

.endproc

.proc reset_enemy

    ldy #MOBILE::state
    lda (mobile_data),y
    cmp #ENEMY_STATE::RETIRED
    bne not_retired
    rts
not_retired:

    jsr init_enemy

    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y
    ldy #ANIM_DATA::sprite
    sta (animation_data_ptr),y

    lda enemy_xstart
    ldy #MOBILE::xpos
    sta (mobile_data),y

    lda #ENEMY_YSTART
    ldy #MOBILE::ypos
    sta (mobile_data),y

    lda #0
    ldy #MOBILE::xvel
    sta (mobile_data),y
    ldy #MOBILE::yvel
    sta (mobile_data),y
    ldy #ENEMY::fire_delay
    sta (mobile_data),y

    lda #DIR::DOWN
    ldy #MOBILE::dir
    sta (mobile_data),y

    ; intentional fall-through to spawn_enemy

.endproc

.proc spawn_enemy

    jsr update_mobile_position
    jsr set_mobile_facing

    ldy #MOBILE_RO::collmask
    lda (mobile_ro_data),y
    tax
    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y
    pha
    jsr set_sprite_collision_mask

    pla
    pha
    ldx #SPRITE_SIZE::W_16
    ldy #SPRITE_SIZE::H_16
    jsr set_sprite_size

    ldy #MOBILE_RO::palette
    lda (mobile_ro_data),y
    tax
    pla
    pha
    jsr set_sprite_palette_offset

    pla
    jmp sprite_enable

.endproc

.proc kill_enemy

    lda #ENEMY_STATE::EXPLODING

    ; intentional fall-through to set_enemy_state

.endproc

.proc set_enemy_state

    ldy #MOBILE::state
    sta (mobile_data),y

    cmp #ENEMY_STATE::DECIDING
    bne not_deciding
    jmp init_deciding
not_deciding:

    cmp #ENEMY_STATE::UTURNING
    bne not_uturning
    jmp init_uturning
not_uturning:

    cmp #ENEMY_STATE::MOVING
    bne not_moving
    jmp init_moving
not_moving:

    cmp #ENEMY_STATE::EXPLODING
    bne not_exploding
    jmp init_exploding
not_exploding:

    cmp #ENEMY_STATE::DEAD
    bne not_dead
    jmp init_dead
not_dead:

    cmp #ENEMY_STATE::RETIRED
    bne not_retired
    jmp init_retired
not_retired:

    cmp #ENEMY_STATE::RESPAWNING
    bne not_respawning
    jmp init_respawning
not_respawning:

    rts

.endproc

.proc update_enemies

    jsr select_first_enemy

    ldx level_enemies
loop:
    phx
    jsr update_enemy
    jsr select_next_enemy
    plx
    dex
    bne loop

    rts

.endproc

.proc update_enemy

    ldy #MOBILE::state
    lda (mobile_data),y

    cmp #ENEMY_STATE::EXPLODING
    bne not_exploding
    jmp update_exploding
not_exploding:

    ldx player_data + MOBILE::state
    cpx #PLAYER_STATE::ALIVE
    beq player_not_dead
    rts
player_not_dead:

    cmp #ENEMY_STATE::UTURNING
    bne not_uturning
    jmp update_uturning
not_uturning:

    cmp #ENEMY_STATE::MOVING
    bne not_moving
    jmp update_moving
not_moving:

    cmp #ENEMY_STATE::DEAD
    bne not_dead
    jmp update_dead
not_dead:

    cmp #ENEMY_STATE::RESPAWNING
    bne not_respawning
    jmp update_respawning
not_respawning:

    rts

.endproc

.proc init_deciding

    ; stay out of left and right border aisles
    ldy #MOBILE::xpos
    lda (mobile_data),y
    ldy #MOBILE_RO::xmin
    cmp (mobile_ro_data),y
    beq do_uturn
    ldy #MOBILE_RO::xmax
    cmp (mobile_ro_data),y
    beq do_uturn

    ; stay out of top and bottom border aisles
    ldy #MOBILE::ypos
    lda (mobile_data),y
    ldy #MOBILE_RO::ymin
    cmp (mobile_ro_data),y
    beq do_uturn
    ldy #MOBILE_RO::ymax
    cmp (mobile_ro_data),y
    beq do_uturn

    ; if enemy is facing a barrier, turn left or right
    jsr is_mobile_facing_barrier
    beq no_barrier
    jsr entropy_get
    bra turning
no_barrier:

    ; if enemy has line-of-sight to player, move toward player
    jsr check_line_of_sight
    beq random_dir
    bne resolve_turn

    ; choose a random direction to turn
random_dir:
    jsr entropy_get

    ; 50% chance to keep current direction, otherwise turn
    lsr
    bcc complete_move

    ; 50% chance to turn clockwise, otherwise turn counterclockwise
turning:
    lsr
    ldy #MOBILE::dir
    lda (mobile_data),y
    bcc turn_cw
    jsr get_ccw_direction
    bra resolve_turn
turn_cw:
    jsr get_cw_direction

resolve_turn:
    cmp #DIR::RIGHT
    beq move_right
    cmp #DIR::LEFT
    beq move_left
    cmp #DIR::DOWN
    beq move_down

move_up:
    lda #DIR::UP
    ldy #MOBILE::dir
    sta (mobile_data),y
    bra complete_move

move_right:
    lda #DIR::RIGHT
    ldy #MOBILE::dir
    sta (mobile_data),y
    bra complete_move

move_left:
    lda #DIR::LEFT
    ldy #MOBILE::dir
    sta (mobile_data),y
    bra complete_move

move_down:
    lda #DIR::DOWN
    ldy #MOBILE::dir
    sta (mobile_data),y

complete_move:
    jsr is_mobile_facing_barrier
    beq no_barrier2
    ldy #MOBILE::dir
    lda (mobile_data),y
    jsr get_reverse_direction
    ldy #MOBILE::dir
    sta (mobile_data),y
no_barrier2:
    lda #ENEMY_STATE::MOVING
    jmp set_enemy_state

do_uturn:
    lda #ENEMY_STATE::UTURNING
    jmp set_enemy_state

.endproc

.proc check_line_of_sight

    ; horizontal in-line check
    ldy #MOBILE::ypos
    lda (mobile_data),y
    cmp player_data + MOBILE::ypos
    beq horizontal

    ; vertical in-line check
    ldy #MOBILE::xpos
    lda (mobile_data),y
    cmp player_data + MOBILE::xpos
    beq vertical

    ; not in-line
    bra false

horizontal:
    ldy #MOBILE::xpos
    lda (mobile_data),y
    cmp player_data + MOBILE::xpos
    bcc player_is_right

player_is_left:
    lda #DIR::LEFT
    bra check_behind

player_is_right:
    lda #DIR::RIGHT
    bra check_behind

vertical:
    ldy #MOBILE::ypos
    lda (mobile_data),y
    cmp player_data + MOBILE::ypos
    bcc player_is_down

player_is_up:
    lda #DIR::UP
    bra check_behind

player_is_down:
    lda #DIR::DOWN

check_behind:
    pha
    jsr get_reverse_direction
    ldy #MOBILE::dir
    cmp (mobile_data),y
    bne true
    pla

false:
    lda #DIR::NONE
    rts

true:
    pla
    rts

.endproc

.proc set_velocity_for_dir

    ldy #MOBILE::dir
    lda (mobile_data),y
    cmp #DIR::UP
    beq move_up
    cmp #DIR::RIGHT
    beq move_right
    cmp #DIR::LEFT
    beq move_left
    cmp #DIR::DOWN
    beq move_down
    rts

move_up:
    lda #0
    ldy #MOBILE::xvel
    sta (mobile_data),y
    lda #SHIP_VEL_NEG
    ldy #MOBILE::yvel
    sta (mobile_data),y
    rts

move_right:
    lda #SHIP_VEL_POS
    ldy #MOBILE::xvel
    sta (mobile_data),y
    lda #0
    ldy #MOBILE::yvel
    sta (mobile_data),y
    rts

move_left:
    lda #SHIP_VEL_NEG
    ldy #MOBILE::xvel
    sta (mobile_data),y
    lda #0
    ldy #MOBILE::yvel
    sta (mobile_data),y
    rts

move_down:
    lda #0
    ldy #MOBILE::xvel
    sta (mobile_data),y
    lda #SHIP_VEL_POS
    ldy #MOBILE::yvel
    sta (mobile_data),y
    rts

.endproc

.proc init_uturning

    ldy #MOBILE::dir
    lda (mobile_data),y
    jsr get_reverse_direction
    ldy #MOBILE::dir
    sta (mobile_data),y
    jmp set_mobile_facing

.endproc

.proc update_uturning

    lda #ENEMY_STATE::MOVING
    jmp set_enemy_state

.endproc

.proc init_moving

    jsr set_mobile_facing
    jmp set_velocity_for_dir

.endproc

.proc update_moving

    ldy #ENEMY::fire_delay
    lda (mobile_data),y
    beq check_fire
    dec
    sta (mobile_data),y
    bne update
    jsr fire_enemy_bullet

check_fire:
    jsr check_line_of_sight
    ldy #MOBILE::dir
    cmp (mobile_data),y
    bne update
    jsr can_enemy_fire
    beq update

    lda #ENEMY_FIRE_DELAY
    ldy #ENEMY::fire_delay
    sta (mobile_data),y

update:
    jsr update_ship_position
    bne deciding

    sec
    ldy #MOBILE::xpos
    lda (mobile_data),y
    ldy #MOBILE_RO::xmin
    sbc (mobile_ro_data),y
    and #%00011111
    bne not_deciding

    sec
    ldy #MOBILE::ypos
    lda (mobile_data),y
    ldy #MOBILE_RO::ymin
    sbc (mobile_ro_data),y
    and #%00011111
    bne not_deciding

deciding:
    lda #ENEMY_STATE::DECIDING
    jmp set_enemy_state

not_deciding:
    rts

.endproc

.proc init_exploding

    jsr play_crash_sound

    lda #0
    ldy #MOBILE::xvel
    sta (mobile_data),y
    ldy #MOBILE::yvel
    sta (mobile_data),y
    ldy #ANIM_DATA::delay
    sta (animation_data_ptr),y

    ldy #ANIM_DATA::table
    lda #<enemy_death_animation
    sta (animation_data_ptr),y
    iny
    lda #>enemy_death_animation
    sta (animation_data_ptr),y

    jmp add_score

.endproc

.proc update_exploding

    jsr update_animation
    beq still_exploding
    lda #ENEMY_STATE::DEAD
    jmp set_enemy_state

still_exploding:
    rts

.endproc

.proc init_dead

    ldy #MOBILE_RO::sprite
    lda (mobile_ro_data),y
    jmp sprite_disable

.endproc

.proc update_dead

    lda active_pellets
    beq retire_enemy
    lda #ENEMY_STATE::RESPAWNING
    bra set_state
retire_enemy:
    lda #ENEMY_STATE::RETIRED
set_state:
    jmp set_enemy_state

.endproc

.proc init_retired

    dec active_enemies
    rts

.endproc

.proc init_respawning

    lda #0
    ldy #ANIM_DATA::delay
    sta (animation_data_ptr),y

    ldy #MOBILE::xvel
    sta (mobile_data),y
    ldy #ENEMY::fire_delay
    sta (mobile_data),y

    lda player_data + MOBILE::xpos
    cmp #(((SHIP_XMAX - SHIP_XMIN) / 2) + SHIP_XMIN)
    bcc spawn_right
    lda #DIR::RIGHT
    ldy #MOBILE::dir
    sta (mobile_data),y
    lda #SHIP_XMIN
    bra set_x
spawn_right:
    lda #DIR::LEFT
    ldy #MOBILE::dir
    sta (mobile_data),y
    lda #SHIP_XMAX
set_x:
    ldy #MOBILE::xpos
    sta (mobile_data),y

    lda player_data + MOBILE::ypos
    cmp #(((SHIP_YMAX - SHIP_YMIN) / 2) + SHIP_YMIN)
    bcc spawn_down
    lda #SHIP_VEL_POS
    ldy #MOBILE::yvel
    sta (mobile_data),y
    lda #SHIP_YMIN
    bra set_y
spawn_down:
    lda #SHIP_VEL_NEG
    ldy #MOBILE::yvel
    sta (mobile_data),y
    lda #SHIP_YMAX
set_y:
    ldy #MOBILE::ypos
    sta (mobile_data),y

    jmp spawn_enemy

.endproc

.proc update_respawning

    ; update position
    jsr update_mobile_position

    ; check if we're at an intersection
    sec
    ldy #MOBILE::ypos
    lda (mobile_data),y
    ldy #MOBILE_RO::ymin
    sbc (mobile_ro_data),y
    beq not_entering
    and #%00011111
    bne not_entering

    ; if this is the 4th intersection, we have to take it
    ldy #ANIM_DATA::delay
    lda (animation_data_ptr),y
    inc
    cmp #4
    beq entering
    sta (animation_data_ptr),y

    ; if the player is visible from this intersection, take it
    jsr check_line_of_sight
    bne entering

    ; 25% chance to take this intersection
    jsr entropy_get
    bit #%00000011
    bne not_entering

entering:
    lda #ENEMY_STATE::MOVING
    jmp set_enemy_state

not_entering:
    rts

.endproc

.rodata

enemy_ro_data:

; enemy 0
.byte $02                                           ; sprite
.byte $01                                           ; palette
.word ENEMY_H_SPRITE_PTR                            ; horiz_ptr
.word ENEMY_V_SPRITE_PTR                            ; vert_ptr
.byte SHIP_XMIN                                     ; xmin
.byte SHIP_XMAX                                     ; xmax
.byte SHIP_YMIN                                     ; ymin
.byte SHIP_YMAX                                     ; ymax
.byte COLL_MASK::PLAYER | COLL_MASK::PLAYER_BULLET  ; collmask

; enemy 1
.byte $03                                           ; sprite
.byte $02                                           ; palette
.word ENEMY_H_SPRITE_PTR                            ; horiz_ptr
.word ENEMY_V_SPRITE_PTR                            ; vert_ptr
.byte SHIP_XMIN                                     ; xmin
.byte SHIP_XMAX                                     ; xmax
.byte SHIP_YMIN                                     ; ymin
.byte SHIP_YMAX                                     ; ymax
.byte COLL_MASK::PLAYER | COLL_MASK::PLAYER_BULLET  ; collmask

; enemy 2
.byte $04                                           ; sprite
.byte $03                                           ; palette
.word ENEMY_H_SPRITE_PTR                            ; horiz_ptr
.word ENEMY_V_SPRITE_PTR                            ; vert_ptr
.byte SHIP_XMIN                                     ; xmin
.byte SHIP_XMAX                                     ; xmax
.byte SHIP_YMIN                                     ; ymin
.byte SHIP_YMAX                                     ; ymax
.byte COLL_MASK::PLAYER | COLL_MASK::PLAYER_BULLET  ; collmask

; enemy 3
.byte $05                                           ; sprite
.byte $04                                           ; palette
.word ENEMY_H_SPRITE_PTR                            ; horiz_ptr
.word ENEMY_V_SPRITE_PTR                            ; vert_ptr
.byte SHIP_XMIN                                     ; xmin
.byte SHIP_XMAX                                     ; xmax
.byte SHIP_YMIN                                     ; ymin
.byte SHIP_YMAX                                     ; ymax
.byte COLL_MASK::PLAYER | COLL_MASK::PLAYER_BULLET  ; collmask

; enemy 4
.byte $06                                           ; sprite
.byte $05                                           ; palette
.word ENEMY_H_SPRITE_PTR                            ; horiz_ptr
.word ENEMY_V_SPRITE_PTR                            ; vert_ptr
.byte SHIP_XMIN                                     ; xmin
.byte SHIP_XMAX                                     ; xmax
.byte SHIP_YMIN                                     ; ymin
.byte SHIP_YMAX                                     ; ymax
.byte COLL_MASK::PLAYER | COLL_MASK::PLAYER_BULLET  ; collmask

enemy_death_animation:

.byte ANIM_CMD::COLL_MASK, 0
.byte ANIM_CMD::SIZE, SPRITE_SIZE::W_32, SPRITE_SIZE::H_32
.byte ANIM_CMD::FLIP, 0, 0
.byte ANIM_CMD::RELPOS, <(-4), <(-2)
.byte ANIM_CMD::PALETTE, 6
.byte ANIM_CMD::IMAGE
.word EXPLOSION_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, ENEMY_EXPLOSION_FRAMES
.byte ANIM_CMD::IMAGE
.word EXPLOSION_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, ENEMY_EXPLOSION_FRAMES
.byte ANIM_CMD::IMAGE
.word EXPLOSION_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, ENEMY_EXPLOSION_FRAMES
.byte ANIM_CMD::STOP
