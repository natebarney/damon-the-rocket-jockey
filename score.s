.include "color.inc"
.include "graphics.inc"
.include "enemy.inc"
.include "level.inc"
.include "score.inc"
.include "sound.inc"
.include "util.inc"
.include "vera.inc"

INITIAL_SHIPS = $07
INITIAL_LEVEL = 0
INITIAL_LEVEL_NUMBER = $01
INITIAL_ENEMIES = 1
SCORE_INCREMENT = $37

.data

ships: .res 1
level: .res 1
level_number: .res 1
level_enemies: .res 1
score: .res 3
hiscore: .res 3

.code

.proc init_score

    stz hiscore
    stz hiscore+1
    stz hiscore+2

    ; intentional fall-through to reset_score

.endproc

.proc reset_score

    lda #INITIAL_SHIPS
    sta ships
    lda #INITIAL_LEVEL
    sta level
    lda #INITIAL_LEVEL_NUMBER
    sta level_number
    lda #INITIAL_ENEMIES
    sta level_enemies
    stz score
    stz score+1
    stz score+2
    rts

.endproc

.proc add_score

    sed
    clc
    lda #<SCORE_INCREMENT
    adc score
    sta score
    lda score+1
    adc #>SCORE_INCREMENT
    sta score+1
    php
    lda score+2
    adc #^SCORE_INCREMENT
    sta score+2
    bcs max_score
    plp
    cld
    bra check_bonus

max_score:
    plp
    cld
    lda #$99
    sta score
    sta score+1
    sta score+2
    bra no_bonus_ship

check_bonus:
    bcc no_bonus_ship
    jsr inc_ships
no_bonus_ship:

    ; intentional fall-through to draw_score

.endproc

.proc draw_score

    lda #<score
    sta src_ptr
    lda #>score
    sta src_ptr+1

    lda #<strbuf
    sta dest_ptr
    lda #>strbuf
    sta dest_ptr+1

    ldx #3
    jsr value_to_hex_string
    stz strbuf+6

    lda #BOARD_XMIN + 32
    sta xcoord
    lda #BOARD_YMIN + 3
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::CYAN)
    sta color
    lda #<strbuf
    sta copy_ram_ptr
    lda #>strbuf
    sta copy_ram_ptr+1
    jmp draw_diagonal_string

.endproc

.proc inc_ships

    sed
    clc
    lda ships
    adc #$01
    sta ships
    cld
    bcc not_max
    lda #$99
    sta ships
not_max:

    jsr play_bonus_sound
    jmp draw_ships

.endproc

.proc dec_ships

    sed
    sec
    lda ships
    sbc #$01
    sta ships
    cld

    ; intentional fall-through to draw_ships

.endproc

.proc draw_ships

    lda #<ships
    sta src_ptr
    lda #>ships
    sta src_ptr+1

    lda #<strbuf
    sta dest_ptr
    lda #>strbuf
    sta dest_ptr+1

    ldx #1
    jsr value_to_hex_string
    stz strbuf+2

    lda #BOARD_XMIN + 35
    sta xcoord
    lda #BOARD_YMIN + 11
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::CYAN)
    sta color
    lda #<strbuf
    sta copy_ram_ptr
    lda #>strbuf
    sta copy_ram_ptr+1
    jmp draw_string

.endproc

.proc inc_level_number

    ; increment number of enemies, if there's room to do so
    lda level_enemies
    cmp #MAX_ENEMIES
    beq no_increment_enemies
    inc
    sta level_enemies
no_increment_enemies:

    ; increment level layout counter, but not past 9, since after that, it just
    ; repeats the layout
    lda level
    cmp #9
    beq no_increment_level
    inc
    sta level
no_increment_level:

    ; increment level display counter, using BCD
    sed
    clc
    lda level_number
    adc #$01
    sta level_number
    cld
    bcc not_max
    lda #$99
    sta level_number
not_max:
    rts

.endproc

.proc draw_level_number

    lda #<level_number
    sta src_ptr
    lda #>level_number
    sta src_ptr+1

    lda #<strbuf
    sta dest_ptr
    lda #>strbuf
    sta dest_ptr+1

    ldx #1
    jsr value_to_hex_string
    stz strbuf+2

    lda #BOARD_XMIN + 35
    sta xcoord
    lda #BOARD_YMIN + 14
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::CYAN)
    sta color
    lda #<strbuf
    sta copy_ram_ptr
    lda #>strbuf
    sta copy_ram_ptr+1
    jmp draw_string

.endproc

.proc update_hiscore

    ldx #3
loop:
    dex
    lda hiscore,x
    cmp score,x
    bcc update
    bne done
    cpx #0
    bne loop

done:
    rts

update:
    lda score
    sta hiscore
    lda score+1
    sta hiscore+1
    lda score+2
    sta hiscore+2

    ; intentional fallthrough to draw_hiscore

.endproc

.proc draw_hiscore

    lda #<hiscore
    sta src_ptr
    lda #>hiscore
    sta src_ptr+1

    lda #<strbuf
    sta dest_ptr
    lda #>strbuf
    sta dest_ptr+1

    ldx #3
    jsr value_to_hex_string
    stz strbuf+6

    lda #BOARD_XMIN + 32
    sta xcoord
    lda #BOARD_YMIN + 17
    sta ycoord
    lda #((COLOR::RED << 4) | COLOR::CYAN)
    sta color
    lda #<strbuf
    sta copy_ram_ptr
    lda #>strbuf
    sta copy_ram_ptr+1
    jmp draw_diagonal_string

.endproc
