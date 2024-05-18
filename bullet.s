.include "bullet.inc"
.include "collision.inc"
.include "enemy.inc"
.include "input.inc"
.include "level.inc"
.include "mobile.inc"
.include "player.inc"
.include "ship.inc"
.include "score.inc"
.include "sound.inc"
.include "sprite.inc"

BULLET_SIZE = 8
BULLET_XMIN = BOARD_XMIN * TILE_SIZE + BORDER_THICKNESS
BULLET_YMIN = BOARD_YMIN * TILE_SIZE + BORDER_THICKNESS
BULLET_XMAX = BULLET_XMIN + BOARD_WIDTH * BLOCK_SIZE - BULLET_SIZE
BULLET_YMAX = BULLET_YMIN + BOARD_HEIGHT * BLOCK_SIZE - BULLET_SIZE

BULLET_VEL_POS = 8
BULLET_VEL_NEG = <(-BULLET_VEL_POS)

ENEMY_RECHARGE_FRAMES = 300

.enum BULLET_STATE
    HIDDEN      = 0
    STOPPED     = 1
    SPAWNING    = 2
    FIRING      = 3
    FROZEN      = 4
.endenum

.zeropage

bullet_data: .res 2
bullet_ro_data: .res 2

.data

is_player_bullet: .res 1
bullet_update_rv: .res 1
enemy_recharge: .res 2
player_bullet_data: .tag MOBILE
enemy_bullet_data: .tag MOBILE

.code

.proc select_player_bullet

    lda #<player_bullet_data
    sta bullet_data
    lda #>player_bullet_data
    sta bullet_data+1

    lda #<player_bullet_ro_data
    sta bullet_ro_data
    lda #>player_bullet_ro_data
    sta bullet_ro_data+1

    lda #$ff
    sta is_player_bullet

    rts

.endproc

.proc select_enemy_bullet

    lda #<enemy_bullet_data
    sta bullet_data
    lda #>enemy_bullet_data
    sta bullet_data+1

    lda #<enemy_bullet_ro_data
    sta bullet_ro_data
    lda #>enemy_bullet_ro_data
    sta bullet_ro_data+1

    lda #0
    sta is_player_bullet

    rts

.endproc

.proc init_bullets

    lda #<ENEMY_RECHARGE_FRAMES
    sta enemy_recharge
    lda #>ENEMY_RECHARGE_FRAMES
    sta enemy_recharge+1

    jsr select_player_bullet
    jsr init_bullet
    jsr select_enemy_bullet
    ; intentional fall-through to init_bullet

.endproc

.proc init_bullet

    lda #DIR::NONE
    ldy #MOBILE::dir
    sta (bullet_data),y

    lda #BULLET_STATE::HIDDEN
    ldy #MOBILE::state
    sta (bullet_data),y

    lda #0
    ldy #MOBILE::xpos
    sta (bullet_data),y
    ldy #MOBILE::ypos
    sta (bullet_data),y
    ldy #MOBILE::xvel
    sta (bullet_data),y
    ldy #MOBILE::yvel
    sta (bullet_data),y

    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    jmp sprite_disable

.endproc

.proc handle_player_fire

    lda current_input
    and #INPUT::FIRE
    beq done
    jsr can_player_fire
    beq done
    jmp fire_player_bullet

done:
    rts

.endproc

.proc can_player_fire

    ; if the bullet is in flight, we can't fire
    lda player_bullet_data + MOBILE::state
    cmp #BULLET_STATE::HIDDEN
    beq maybe
    cmp #BULLET_STATE::STOPPED
    beq maybe
    bra false
maybe:

    lda player_data + MOBILE::dir
check_right:
    cmp #DIR::RIGHT
    bne check_left
    lda player_data + MOBILE::xpos
    cmp #SHIP_XMAX
    bcc true
    bra false

check_left:
    cmp #DIR::LEFT
    bne check_down
    lda #SHIP_XMIN
    cmp player_data + MOBILE::xpos
    bcc true
    bra false

check_down:
    cmp #DIR::DOWN
    bne check_up
    lda player_data + MOBILE::ypos
    cmp #SHIP_YMAX
    bcc true
    bra false

check_up:
    lda #SHIP_YMIN
    cmp player_data + MOBILE::ypos
    bcc true
    bra false

true:
    lda #$ff
    rts

false:
    lda #0
    rts

.endproc

.proc can_enemy_fire

    ; if we're at a level less than 8, the enemy can't fire
    lda level
    cmp #7
    bcc false

    ; if the bullet is still recharging, the enemy can't fire
    lda enemy_recharge
    ora enemy_recharge+1
    bne false

    ; if the bullet is in flight, the enemy can't fire
    lda enemy_bullet_data + MOBILE::state
    cmp #BULLET_STATE::HIDDEN
    beq true
    cmp #BULLET_STATE::STOPPED
    beq true

false:
    lda #0
    rts

true:
    lda #$ff
    rts

.endproc

.proc fire_player_bullet

    jsr select_player_bullet
    jsr fire_bullet
    jmp play_bullet_sound

.endproc

.proc fire_enemy_bullet

    ; reset enemy recharge counter
    lda #<ENEMY_RECHARGE_FRAMES
    sta enemy_recharge
    lda #>ENEMY_RECHARGE_FRAMES
    sta enemy_recharge+1

    ; save current mobile data pointers
    lda mobile_data
    pha
    lda mobile_data+1
    pha
    lda mobile_ro_data
    pha
    lda mobile_ro_data+1
    pha

    ; fire bullet
    jsr select_enemy_bullet
    jsr fire_bullet

    ; restore previous mobile data pointers
    pla
    sta mobile_ro_data+1
    pla
    sta mobile_ro_data
    pla
    sta mobile_data+1
    pla
    sta mobile_data

    rts

.endproc

.proc fire_bullet

    lda #BULLET_STATE::SPAWNING
    ldy #MOBILE::state
    sta (bullet_data),y

    ldy #MOBILE::dir
    lda (mobile_data),y
    bne store_facing
    lda #DIR::LEFT
store_facing:
    sta (bullet_data),y

check_right:
    cmp #DIR::RIGHT
    bne check_left
    clc
    ldy #MOBILE::xpos
    lda (mobile_data),y
    adc #(SHIP_SIZE - BULLET_SIZE) ; right-align bullet with ship
    sta (bullet_data),y
    lda #BULLET_VEL_POS
    ldy #MOBILE::xvel
    sta (bullet_data),y
    bra horizontal

check_left:
    cmp #DIR::LEFT
    bne check_down
    ldy #MOBILE::xpos
    lda (mobile_data),y
    sta (bullet_data),y
    lda #BULLET_VEL_NEG
    ldy #MOBILE::xvel
    sta (bullet_data),y
    bra horizontal

check_down:
    cmp #DIR::DOWN
    bne check_up
    clc
    ldy #MOBILE::ypos
    lda (mobile_data),y
    adc #(SHIP_SIZE - BULLET_SIZE) ; bottom-align bullet with ship
    sta (bullet_data),y
    lda #BULLET_VEL_POS
    ldy #MOBILE::yvel
    sta (bullet_data),y
    bra vertical

check_up:
    ldy #MOBILE::ypos
    lda (mobile_data),y
    sta (bullet_data),y
    lda #BULLET_VEL_NEG
    ldy #MOBILE::yvel
    sta (bullet_data),y
    bra vertical

horizontal:
    clc
    ldy #MOBILE::xvel
    lda (mobile_data),y
    ldy #MOBILE::xpos
    adc (bullet_data),y ; advance bullet start position by one frame
    sta (bullet_data),y
    clc
    ldy #MOBILE::ypos
    lda (mobile_data),y
    adc #((SHIP_SIZE - BULLET_SIZE) / 2) ; vertically center with ship
    sta (bullet_data),y
    lda #0
    ldy #MOBILE::yvel
    sta (bullet_data),y
    bra done

vertical:
    clc
    ldy #MOBILE::xvel
    lda (mobile_data),y
    ldy #MOBILE::xpos
    adc (bullet_data),y ; advance bullet start position by one frame
    sta (bullet_data),y
    clc
    ldy #MOBILE::xpos
    lda (mobile_data),y
    adc #((SHIP_SIZE - BULLET_SIZE) / 2) ; horizontally center with ship
    sta (bullet_data),y
    lda #0
    ldy #MOBILE::xvel
    sta (bullet_data),y

done:

    lda bullet_data
    sta mobile_data
    lda bullet_data+1
    sta mobile_data+1
    lda bullet_ro_data
    sta mobile_ro_data
    lda bullet_ro_data+1
    sta mobile_ro_data+1
    jsr set_mobile_facing

    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    pha
    ldy #MOBILE::xpos
    lda (bullet_data),y
    tax
    ldy #MOBILE::ypos
    lda (bullet_data),y
    tay
    pla
    jsr set_sprite_pos

    ldy #MOBILE_RO::collmask
    lda (bullet_ro_data),y
    tax
    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    jsr set_sprite_collision_mask

    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    ldx #SPRITE_SIZE::W_08
    ldy #SPRITE_SIZE::H_08
    jsr set_sprite_size

    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    jmp sprite_enable

.endproc

.proc update_bullets

    ; if enemy_recharge is zero, skip decrement
    lda enemy_recharge
    ora enemy_recharge+1
    beq update

    ; decrement enemy_recharge
    sec
    lda enemy_recharge
    sbc #1
    sta enemy_recharge
    lda enemy_recharge+1
    sbc #0
    sta enemy_recharge+1

update:
    jsr select_player_bullet
    jsr update_bullet
    jsr select_enemy_bullet
    ; intentional fall-through to update_bullet

.endproc

.proc update_bullet

    stz bullet_update_rv
    ldy #MOBILE::state
    lda (bullet_data),y
    cmp #BULLET_STATE::STOPPED
    beq hide
    cmp #BULLET_STATE::SPAWNING
    beq spawn
    cmp #BULLET_STATE::FIRING
    beq update
    rts

spawn:
    lda #BULLET_STATE::FIRING
    sta (bullet_data),y
    rts

update:
    lda bullet_data
    sta mobile_data
    lda bullet_data+1
    sta mobile_data+1
    lda bullet_ro_data
    sta mobile_ro_data
    lda bullet_ro_data+1
    sta mobile_ro_data+1
    jsr update_mobile_position
    sta bullet_update_rv

    lda is_player_bullet
    beq check_player_collision

    lda sprite_collisions
    bit #COLL_MASK::PLAYER_BULLET
    bne enemy_collision
    beq check_stop

check_player_collision:
    lda sprite_collisions
    bit #COLL_MASK::ENEMY_BULLET
    bne player_collision
    beq check_stop

enemy_collision:
    jsr check_bullet_enemy_collision
    bne hide
    beq check_stop

player_collision:
    lda #PLAYER_STATE::DYING
    sta player_data + MOBILE::state
    bra hide

check_stop:
    lda bullet_update_rv
    bne stop_bullet
    rts

stop_bullet:
    lda #BULLET_STATE::STOPPED
    ldy #MOBILE::state
    sta (bullet_data),y
    lda #0
    ldy #MOBILE::dir
    sta (bullet_data),y
    ldy #MOBILE::xvel
    sta (bullet_data),y
    ldy #MOBILE::yvel
    sta (bullet_data),y
    rts

hide:
    lda #BULLET_STATE::HIDDEN
    ldy #MOBILE::state
    sta (bullet_data),y

    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    ldx #COLL_MASK::NONE
    jsr set_sprite_collision_mask

    ldy #MOBILE_RO::sprite
    lda (bullet_ro_data),y
    jsr sprite_disable

    lda is_player_bullet
    beq not_player_bullet
    jmp stop_bullet_sound
not_player_bullet:
    rts

.endproc

.proc freeze_bullets

    jsr silence_bullet_sound

    lda #BULLET_STATE::FROZEN
    sta player_bullet_data + MOBILE::state
    sta enemy_bullet_data + MOBILE::state

    lda player_bullet_ro_data + MOBILE_RO::sprite
    ldx #COLL_MASK::NONE
    jsr set_sprite_collision_mask

    lda enemy_bullet_ro_data + MOBILE_RO::sprite
    ldx #COLL_MASK::NONE
    jmp set_sprite_collision_mask

.endproc

.proc load_player_bullet_rect

    ; set x extents to full sprite size
    lda player_bullet_data + MOBILE::xpos
    sta other_rect + RECT::xmin
    clc
    adc #BULLET_SIZE
    sta other_rect + RECT::xmax

    ; set y extents to full sprite size
    lda player_bullet_data + MOBILE::ypos
    sta other_rect + RECT::ymin
    clc
    adc #BULLET_SIZE
    sta other_rect + RECT::ymax

    ; check to see whether the sprite is horizontal or vertical
    lda player_bullet_data + MOBILE::dir
    cmp #DIR::DOWN
    beq vertical
    cmp #DIR::UP
    beq vertical

    ; horizontal - bring y extents in 3 pixels on each side
    lda other_rect + RECT::ymin
    clc
    adc #3
    sta other_rect + RECT::ymin
    lda other_rect + RECT::ymax
    sec
    sbc #3
    sta other_rect + RECT::ymax
    rts

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

.endproc

.proc check_bullet_enemy_collision

    jsr load_player_bullet_rect
    jsr check_enemy_collision
    bne hit
    rts

hit:
    jsr kill_enemy
    lda #$ff
    rts

.endproc

.rodata

player_bullet_ro_data:
.byte $01                           ; sprite
.byte $00                           ; palette
.word PLAYER_BULLET_H_SPRITE_PTR    ; horiz_ptr
.word PLAYER_BULLET_V_SPRITE_PTR    ; vert_ptr
.byte BULLET_XMIN                   ; xmin
.byte BULLET_XMAX                   ; xmax
.byte BULLET_YMIN                   ; ymin
.byte BULLET_YMAX                   ; ymax
.byte COLL_MASK::PLAYER_BULLET      ; collmask

enemy_bullet_ro_data:
.byte $07                       ; sprite
.byte $00                       ; palette
.word ENEMY_BULLET_H_SPRITE_PTR ; horiz_ptr
.word ENEMY_BULLET_V_SPRITE_PTR ; vert_ptr
.byte BULLET_XMIN               ; xmin
.byte BULLET_XMAX               ; xmax
.byte BULLET_YMIN               ; ymin
.byte BULLET_YMAX               ; ymax
.byte COLL_MASK::ENEMY_BULLET   ; collmask
