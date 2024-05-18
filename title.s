.include "animation.inc"
.include "color.inc"
.include "graphics.inc"
.include "input.inc"
.include "kernal.inc"
.include "music.inc"
.include "score.inc"
.include "sprite.inc"
.include "title.inc"
.include "vera.inc"

.struct LETTER_DATA
    sprite_ptr  .word
    sprite      .byte
    palette     .byte
    xpos        .byte
    ypos        .byte
    next_state  .byte
.endstruct

LETTER_ANIMATION_FRAMES = 6
EMERGE_OFFSET = 24

.zeropage

letter_data: .res 2

.data

title_state: .res 1
slide_ypos: .res 1
emerge_frame: .res 1

d_anim: .tag ANIM_DATA
a_anim: .tag ANIM_DATA
m_anim: .tag ANIM_DATA
o_anim: .tag ANIM_DATA
n_anim: .tag ANIM_DATA

.code

.proc init_title_screen

    jsr reset_sprites
    jsr clear_l1_tilemap
    lda #TITLE_STATE::SLIDING_D

    ; intentional fall-through to title_set_state

.endproc

.proc title_set_state

    sta title_state

    cmp #TITLE_STATE::SLIDING_D
    bne not_sliding_d
    jmp title_init_sliding_d
not_sliding_d:

    cmp #TITLE_STATE::SLIDING_A
    bne not_sliding_a
    jmp title_init_sliding_a
not_sliding_a:

    cmp #TITLE_STATE::SLIDING_M
    bne not_sliding_m
    jmp title_init_sliding_m
not_sliding_m:

    cmp #TITLE_STATE::SLIDING_O
    bne not_sliding_o
    jmp title_init_sliding_o
not_sliding_o:

    cmp #TITLE_STATE::SLIDING_N
    bne not_sliding_n
    jmp title_init_sliding_n
not_sliding_n:

    cmp #TITLE_STATE::ANIMATING
    bne not_animating
    jmp title_init_animating
not_animating:

    rts

.endproc

.proc update_title_screen

    lda title_state

    cmp #TITLE_STATE::ANIMATING
    bne not_animating
    jmp title_update_animating
not_animating:

    cmp #TITLE_STATE::DONE
    bne not_done
    rts
not_done:

    ; drain keyboard buffer
    jsr GETIN

    jmp update_letter_slide

.endproc

.proc title_init_sliding_d

    lda #<d_letter_data
    sta letter_data
    lda #>d_letter_data
    sta letter_data+1

    jmp init_letter_slide

.endproc

.proc title_init_sliding_a

    lda #<a_letter_data
    sta letter_data
    lda #>a_letter_data
    sta letter_data+1

    jmp init_letter_slide

.endproc

.proc title_init_sliding_m

    lda #<m_letter_data
    sta letter_data
    lda #>m_letter_data
    sta letter_data+1

    jmp init_letter_slide

.endproc

.proc title_init_sliding_o

    lda #<o_letter_data
    sta letter_data
    lda #>o_letter_data
    sta letter_data+1

    jmp init_letter_slide

.endproc

.proc title_init_sliding_n

    lda #<n_letter_data
    sta letter_data
    lda #>n_letter_data
    sta letter_data+1

    jmp init_letter_slide

.endproc

.proc title_init_animating

    lda #<d_animation_table
    sta d_anim + ANIM_DATA::table
    lda #>d_animation_table
    sta d_anim + ANIM_DATA::table + 1
    stz d_anim + ANIM_DATA::delay
    lda d_letter_data + LETTER_DATA::sprite
    sta d_anim + ANIM_DATA::sprite

    lda #<a_animation_table
    sta a_anim + ANIM_DATA::table
    lda #>a_animation_table
    sta a_anim + ANIM_DATA::table + 1
    stz a_anim + ANIM_DATA::delay
    lda a_letter_data + LETTER_DATA::sprite
    sta a_anim + ANIM_DATA::sprite

    lda #<m_animation_table
    sta m_anim + ANIM_DATA::table
    lda #>m_animation_table
    sta m_anim + ANIM_DATA::table + 1
    stz m_anim + ANIM_DATA::delay
    lda m_letter_data + LETTER_DATA::sprite
    sta m_anim + ANIM_DATA::sprite

    lda #<o_animation_table
    sta o_anim + ANIM_DATA::table
    lda #>o_animation_table
    sta o_anim + ANIM_DATA::table + 1
    stz o_anim + ANIM_DATA::delay
    lda o_letter_data + LETTER_DATA::sprite
    sta o_anim + ANIM_DATA::sprite

    lda #<n_animation_table
    sta n_anim + ANIM_DATA::table
    lda #>n_animation_table
    sta n_anim + ANIM_DATA::table + 1
    stz n_anim + ANIM_DATA::delay
    lda n_letter_data + LETTER_DATA::sprite
    sta n_anim + ANIM_DATA::sprite

    jsr music_load_title
    jsr music_play
    jsr reset_input
    jsr reset_score
    jmp draw_title_screen_text

.endproc

.proc title_update_animating

    jsr GETIN
    cmp #'Q'
    bne not_quitting
    stz $01     ; restore default rom bank
    jmp ($fffa) ; jump to NMI handler (like ctrl-alt-restore)
not_quitting:

    jsr read_input
    lda current_input
    bit #INPUT::FIRE
    beq not_firing
    lda #TITLE_STATE::DONE
    jmp title_set_state
not_firing:

    lda #<d_anim
    sta animation_data_ptr
    lda #>d_anim
    sta animation_data_ptr+1
    jsr update_animation

    lda #<a_anim
    sta animation_data_ptr
    lda #>a_anim
    sta animation_data_ptr+1
    jsr update_animation

    lda #<m_anim
    sta animation_data_ptr
    lda #>m_anim
    sta animation_data_ptr+1
    jsr update_animation

    lda #<o_anim
    sta animation_data_ptr
    lda #>o_anim
    sta animation_data_ptr+1
    jsr update_animation

    lda #<n_anim
    sta animation_data_ptr
    lda #>n_anim
    sta animation_data_ptr+1
    jsr update_animation

    rts

.endproc

.proc draw_title_screen_text

    lda #<title_screen_text
    sta copy_ram_ptr
    lda #>title_screen_text
    sta copy_ram_ptr+1

loop:
    ldy #3
    lda (copy_ram_ptr),y
    beq done

    dey
    lda (copy_ram_ptr),y
    sta color

    dey
    lda (copy_ram_ptr),y
    sta ycoord

    dey
    lda (copy_ram_ptr),y
    sta xcoord

    clc
    lda copy_ram_ptr
    adc #3
    sta copy_ram_ptr
    lda copy_ram_ptr+1
    adc #0
    sta copy_ram_ptr+1

    jsr draw_string
    bra loop

done:
    rts

.endproc

.proc init_letter_slide

    lda #EMERGE_OFFSET
    sta emerge_frame

    clc
    ldy #LETTER_DATA::sprite_ptr
    lda (letter_data),y
    adc #EMERGE_OFFSET
    sta sprite_data_ptr
    iny
    lda (letter_data),y
    adc #0
    sta sprite_data_ptr+1
    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    jsr set_sprite_image

    stz slide_ypos

    ldy #LETTER_DATA::xpos
    lda (letter_data),y
    tax
    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    ldy #0
    jsr set_sprite_pos

    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    ldx #SPRITE_SIZE::W_64
    ldy #SPRITE_SIZE::H_32
    jsr set_sprite_size

    ldy #LETTER_DATA::palette
    lda (letter_data),y
    tax
    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    jsr set_sprite_palette_offset

    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    jmp sprite_enable

.endproc

.proc update_letter_slide

    lda emerge_frame
    beq slide

    dec emerge_frame
    dec emerge_frame
    clc
    ldy #LETTER_DATA::sprite_ptr
    lda (letter_data),y
    adc emerge_frame
    sta sprite_data_ptr
    iny
    lda (letter_data),y
    adc #0
    sta sprite_data_ptr+1
    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    jmp set_sprite_image

slide:

    inc slide_ypos
    ldy #LETTER_DATA::ypos
    lda (letter_data),y
    cmp slide_ypos
    beq done_incrementing
    inc slide_ypos
done_incrementing:

    ldy #LETTER_DATA::xpos
    lda (letter_data),y
    tax
    ldy #LETTER_DATA::sprite
    lda (letter_data),y
    ldy slide_ypos
    jsr set_sprite_pos

    ldy #LETTER_DATA::ypos
    lda (letter_data),y
    cmp slide_ypos
    beq done_sliding
    rts

done_sliding:
    ldy #LETTER_DATA::next_state
    lda (letter_data),y
    jmp title_set_state

.endproc

.rodata

d_letter_data:
.word D_1_SPRITE_PTR            ; sprite_ptr
.byte 0                         ; sprite
.byte 0                         ; palette (white)
.byte 15 + 60 * 0               ; xpos
.byte 21 +  7 * 0               ; ypos
.byte TITLE_STATE::SLIDING_A    ; next_state

a_letter_data:
.word A_1_SPRITE_PTR            ; sprite_ptr
.byte 1                         ; sprite
.byte 7                         ; palette (cyan)
.byte 15 + 60 * 1               ; xpos
.byte 21 +  7 * 1               ; ypos
.byte TITLE_STATE::SLIDING_M    ; next_state

m_letter_data:
.word M_1_SPRITE_PTR            ; sprite_ptr
.byte 2                         ; sprite
.byte 2                         ; palette (green)
.byte 15 + 60 * 2               ; xpos
.byte 21 +  7 * 2               ; ypos
.byte TITLE_STATE::SLIDING_O    ; next_state

o_letter_data:
.word O_1_SPRITE_PTR            ; sprite_ptr
.byte 3                         ; sprite
.byte 3                         ; palette (blue)
.byte 15 + 60 * 3               ; xpos
.byte 21 +  7 * 3               ; ypos
.byte TITLE_STATE::SLIDING_N    ; next_state

n_letter_data:
.word N_1_SPRITE_PTR            ; sprite_ptr
.byte 4                         ; sprite
.byte 4                         ; palette (yellow)
.byte 15 + 60 * 4               ; xpos
.byte 21 +  7 * 4               ; ypos
.byte TITLE_STATE::ANIMATING    ; next_state

title_screen_text:
.byte 11, 9, COLOR::PURPLE
.asciiz "THE ROCKET JOCKEY"
.byte 9, 13, COLOR::L_RED
.asciiz "WRITTEN BY"
.byte 20, 13, COLOR::WHITE
.asciiz "NATE BARNEY"
.byte 11, 15, COLOR::L_BLUE
.asciiz "@ 2024 NATE BARNEY"
.byte 4, 18, COLOR::L_RED
.asciiz "BASED ON"
.byte 13, 18, COLOR::PURPLE
.asciiz "NOMAD: THE SPACE PIRATE"
.byte 10, 20, COLOR::L_BLUE
.asciiz "@ 1985 MIKE POULLAS"
.byte 7, 24, COLOR::YELLOW
.asciiz "PRESS FIRE BUTTON TO PLAY"
.byte 11, 26, COLOR::YELLOW
.asciiz "PRESS ` ' TO QUIT."
.byte 18, 26, COLOR::WHITE
.asciiz "Q"
.byte 35, 29, COLOR::D_GREY
.asciiz "1.0.0"
.byte 0, 0, 0, 0

d_animation_table:

.byte ANIM_CMD::IMAGE
.word D_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word D_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::IMAGE
.word D_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word D_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::JUMP
.addr d_animation_table

a_animation_table:

.byte ANIM_CMD::IMAGE
.word A_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word A_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::IMAGE
.word A_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word A_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::JUMP
.addr a_animation_table

m_animation_table:

.byte ANIM_CMD::IMAGE
.word M_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word M_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::IMAGE
.word M_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word M_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::JUMP
.addr m_animation_table

o_animation_table:

.byte ANIM_CMD::IMAGE
.word O_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word O_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::IMAGE
.word O_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word O_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::JUMP
.addr o_animation_table

n_animation_table:

.byte ANIM_CMD::IMAGE
.word N_1_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word N_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::IMAGE
.word N_3_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES
.byte ANIM_CMD::IMAGE
.word N_2_SPRITE_PTR
.byte ANIM_CMD::DELAY, LETTER_ANIMATION_FRAMES + 1
.byte ANIM_CMD::JUMP
.addr n_animation_table
