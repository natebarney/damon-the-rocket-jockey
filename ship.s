.include "barrier.inc"
.include "level.inc"
.include "mobile.inc"
.include "ship.inc"

SHIP_SIZE = 16
SHIP_XMIN = BOARD_XMIN * TILE_SIZE + BORDER_THICKNESS
SHIP_YMIN = BOARD_YMIN * TILE_SIZE + BORDER_THICKNESS
SHIP_XMAX = SHIP_XMIN + BOARD_WIDTH * BLOCK_SIZE - SHIP_SIZE
SHIP_YMAX = SHIP_YMIN + BOARD_HEIGHT * BLOCK_SIZE - SHIP_SIZE

SHIP_VEL_POS = 2
SHIP_VEL_NEG = <(-SHIP_VEL_POS)

.code

.proc update_ship_position

    jsr is_mobile_facing_barrier
    bne stop_ship
    jmp update_mobile_position

stop_ship:
    lda #0
    ldy #MOBILE::xvel
    sta (mobile_data),y
    ldy #MOBILE::yvel
    sta (mobile_data),y
    lda #$ff
    rts

.endproc