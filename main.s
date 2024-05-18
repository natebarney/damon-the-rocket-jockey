.include "game.inc"
.include "graphics.inc"
.include "irq.inc"
.include "main.inc"

.segment "MAIN"

; program entry point
.proc main

    jsr init_graphics
    jsr game_init
    jsr install_irq_handler

wait:
    wai
    lda new_frame
    beq wait
    stz new_frame
    jsr game_update
    bra wait

.endproc

.rodata

