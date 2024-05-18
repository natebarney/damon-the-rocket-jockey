.include "collision.inc"
.include "irq.inc"
.include "vera.inc"

IRQ_VECTOR := $0314

.zeropage

new_frame: .res 1

.data

old_handler: .res 2

.code

.proc install_irq_handler

    sei

    stz new_frame
    stz sprite_collisions

    ; save old handler
    lda IRQ_VECTOR
    sta old_handler
    lda IRQ_VECTOR+1
    sta old_handler+1

    ; install new handler
    lda #<irq_handler
    sta IRQ_VECTOR
    lda #>irq_handler
    sta IRQ_VECTOR+1

    ; enable VERA VSYNC and SPRCOL interrupts, disable other VERA interrupts
    lda #(VERA::IRQ_MASK::VSYNC | VERA::IRQ_MASK::SPRCOL)
    sta VERA::IER

    ; clear pending VERA interrupts
    lda %00000111
    sta VERA::ISR

    cli

    rts

.endproc

.proc irq_handler

    pha
    cld

    ; check if this is a VSYNC interrupt
    lda VERA::ISR
    bit #VERA::IRQ_MASK::VSYNC
    beq no_vsync_irq
    inc new_frame
no_vsync_irq:
    bit #VERA::IRQ_MASK::SPRCOL
    beq no_sprcol_irq
    and #%11110000
    sta sprite_collisions
    lda #VERA::IRQ_MASK::SPRCOL
    sta VERA::ISR
    bra done
no_sprcol_irq:
    stz sprite_collisions

done:
    pla
    ; chain to original handler
    jmp (old_handler)

.endproc