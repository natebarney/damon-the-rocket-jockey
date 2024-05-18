.include "collision.inc"
.include "enemy.inc"
.include "mobile.inc"
.include "score.inc"

.zeropage

sprite_collisions: .res 1

.data

enemy_rect: .tag RECT
other_rect: .tag RECT

.code

.proc rects_intersect

    ; if (enemy_rect.xmin > other_rect.xmax) return false
    lda other_rect + RECT::xmax
    cmp enemy_rect + RECT::xmin
    bcc false

    ; if (other_rect.xmin > enemy_rect.xmax) return false
    lda enemy_rect + RECT::xmax
    cmp other_rect + RECT::xmin
    bcc false

    ; if (enemy_rect.ymin > other_rect.ymax) return false
    lda other_rect + RECT::ymax
    cmp enemy_rect + RECT::ymin
    bcc false

    ; if (other_rect.ymin > enemy_rect.ymax) return false
    lda enemy_rect + RECT::ymax
    cmp other_rect + RECT::ymin
    bcc false

true:
    lda #$ff
    rts

false:
    lda #0
    rts

.endproc

.proc check_enemy_collision

    jsr select_first_enemy

    ldx level_enemies
loop:
    lda #ENEMY_STATE::MOVING
    ldy #MOBILE::state
    cmp (mobile_data),y
    bcc next
    jsr load_enemy_rect
    jsr rects_intersect
    bne hit
next:
    jsr select_next_enemy
    dex
    bne loop

    lda #0
    rts

hit:
    lda #$ff
    rts

.endproc
