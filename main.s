.include "game.inc"
.include "graphics.inc"
.include "irq.inc"
.include "main.inc"
.include "pcm.inc"

.segment "MAIN"

; program entry point
.proc main

    jsr init_pcm
    jsr load_clips
    jsr init_graphics
    jsr game_init
    jsr install_irq_handler

wait:
    wai
    lda new_frame
    beq wait
    stz new_frame
    jsr game_update
    jsr fill_fifo
    bra wait

.endproc

.rodata

