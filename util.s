.include "util.inc"

.zeropage

src_ptr: .res 2
dest_ptr: .res 2

.data

buffer_offset: .res 1

.code

;
; petscii_to_screen_code - convert a petscii character to a screen code
;
; Parameters:
;
;   A - petscii character
;
; Returns:
;
;   A - screen code
;
; Clobbers:
;
;   ZF, CF, NF
;
.proc petscii_to_screen_code

    cmp #$20
    bcc set_bit_7
    cmp #$40
    bcc unmodified
    cmp #$60
    bcc clear_bit_6
    cmp #$80
    bcc clear_bit_5
    cmp #$a0
    bcc set_bit_6
    cmp #$c0
    bcc clear_bit_6
    cmp #$ff
    bcc clear_bit_7
    lda $5e

unmodified:
    rts

set_bit_7:
    ora #%10000000
    rts

clear_bit_6:
    and #%10111111
    rts

clear_bit_5:
    and #%11011111
    rts

set_bit_6:
    ora #%01000000
    rts

clear_bit_7:
    and #%01111111
    rts

.endproc

;
; value_to_hex_string - convert a multi-byte little-endian value to hex
;   digit petscii characters into a buffer
;
; Parameters:
;
;   X - number of bytes to convert
;   dest_ptr - pointer to destination buffer
;   src_ptr - pointer to source value
;
; Clobbers:
;
;   A, X, Y, CF, ZF, NF, VF
;
.proc value_to_hex_string
    lda #0
    sta buffer_offset
loop:
    dex
    txa
    tay
    lda (src_ptr),y
    ldy buffer_offset
    jsr byte_to_hex_string
    sty buffer_offset
    cpx #0
    bne loop
    rts
.endproc ; value_to_hex_string

;
; byte_to_hex_string - convert one byte to hex digit petscii characters into a
;   buffer
;
; Parameters:
;
;   A - byte to convert
;   dest_ptr - pointer to destination buffer
;   Y - destination buffer offset
;
; Returns:
;
;   Y - updated destination buffer offset
;
; Clobbers:
;
;   A, CF, ZF, NF, VF
;
.proc byte_to_hex_string

    ; convert high nibble
    pha
    lsr
    lsr
    lsr
    lsr
    jsr nibble_to_hex_char
    sta (dest_ptr),y
    iny

    ; convert low nibble
    pla
    jsr nibble_to_hex_char
    sta (dest_ptr),y
    iny

    rts

.endproc ; byte_to_hex_string

;
; nibble_to_hex_char - convert the low nibble of A to a hex digit petscii
;   character
;
; Parameters:
;
;   A - value with low nibble to convert
;
; Returns:
;
;   A - hex digit petscii character
;
; Clobbers:
;
;   CF, ZF, NF, VF
;
.proc nibble_to_hex_char

    and #%00001111
    cmp #10
    bcs letter

digit:
    adc #$30
    rts

letter:
    adc #$36
    rts

.endproc ; nibble_to_hex_char
