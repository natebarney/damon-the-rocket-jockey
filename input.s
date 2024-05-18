.include "input.inc"
.include "kernal.inc"

.data

joystick: .res 1
frame_input: .res 1
current_input: .res 1

.code

.proc reset_input

    stz frame_input
    stz current_input
    rts

.endproc

.proc read_input

    ; get the AND (deMorgan OR) of all 5 sets of joystick bits
    ; into frame_input
    lda #$ff
    sta frame_input
    lda #0
    sta joystick
loop:
    jsr joystick_get
    and frame_input
    sta frame_input
    txa
    and frame_input
    sta frame_input
    inc joystick
    lda joystick
    cmp #5
    bne loop

    ; invert the input bits
    lda frame_input
    eor #$ff
    sta frame_input

check_left_right:
    ; if player pressed both left and right, cancel them both out
    and #(INPUT::LEFT | INPUT::RIGHT)
    cmp #(INPUT::LEFT | INPUT::RIGHT)
    bne check_up_down
    lda frame_input
    and #<(~(INPUT::LEFT | INPUT::RIGHT))
    sta frame_input

check_up_down:
    ; if player pressed both up and down, cancel them both out
    lda frame_input
    and #(INPUT::UP | INPUT::DOWN)
    cmp #(INPUT::UP | INPUT::DOWN)
    bne check_dir
    lda frame_input
    and #<(~(INPUT::UP | INPUT::DOWN))
    sta frame_input

check_dir:
    ; check to see if the player pressed a direction
    lda frame_input
    and #(INPUT::LEFT | INPUT::RIGHT | INPUT::UP | INPUT::DOWN)
    beq no_dir
    sta current_input

no_dir:
    ; clear any previously pressed button bit
    lda current_input
    and #(INPUT::LEFT | INPUT::RIGHT | INPUT::UP | INPUT::DOWN)
    sta current_input

    ; check to see if the player pressed a button
    lda frame_input
    and #<(~(INPUT::LEFT | INPUT::RIGHT | INPUT::UP | INPUT::DOWN))
    beq no_button

    ; set the pressed button bit
    lda current_input
    ora #INPUT::FIRE
    sta current_input

no_button:
    rts

.endproc

.proc clear_steering_input

    lda current_input
    and #<(~(INPUT::LEFT | INPUT::RIGHT | INPUT::UP | INPUT::DOWN))
    sta current_input
    rts

.endproc
