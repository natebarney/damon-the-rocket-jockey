.include "sound.inc"
.include "vera.inc"

.enum CHANNEL
    BULLET = 0
    CRASH = 1
    BONUS = 2
.endenum

.enum WAVEFORM
    PULSE = (0 << 6)
    SAWTOOTH = (1 << 6)
    TRIANGLE = (2 << 6)
    NOISE = (3 << 6)
.endenum

VOLUME_MAX = 63
VOLUME_MIN = 0

BULLET_FREQ = 2362
BULLET_FREQ_STEP = 32
BULLET_INIT_VOLUME = VOLUME_MAX
BULLET_VOL_STEP = 12

.enum BULLET_STATE
    DONE = 0
    PLAYING = 1
    FADING = 2
.endenum

CRASH_FRAMES = 30
CRASH_FREQ = BULLET_FREQ * 5
CRASH_INIT_VOLUME = VOLUME_MAX
CRASH_VOL_STEP = 2

BONUS_FRAMES = 10
BONUS_VOLUME = VOLUME_MAX
BONUS_FREQ = 3044 ; 1134 Hz / ((25e6 / 512) / (2^17))

.data

bullet_state: .res 1
bullet_freq: .res 2
bullet_volume: .res 1

crash_frames: .res 1
crash_volume: .res 1

bonus_frames: .res 1

.code

.proc sound_init

    lda #CHANNEL::BULLET
    ldx #WAVEFORM::TRIANGLE
    ldy #0
    sty bullet_volume
    sty bullet_freq
    sty bullet_freq+1
    sty bullet_state
    jsr set_psg_waveform_volume

    lda #CHANNEL::CRASH
    ldx #WAVEFORM::NOISE
    ldy #0
    sty crash_frames
    sty crash_volume
    jmp set_psg_waveform_volume

    lda #CHANNEL::BONUS
    ldx #WAVEFORM::SAWTOOTH
    ldy #0
    sty bonus_frames
    jmp set_psg_waveform_volume

.endproc

.proc play_bullet_sound

    lda #BULLET_STATE::PLAYING
    sta bullet_state

    lda #CHANNEL::BULLET
    ldx #<BULLET_FREQ
    stx bullet_freq
    ldy #>BULLET_FREQ
    sty bullet_freq+1
    jsr set_psg_frequency

    lda #CHANNEL::BULLET
    ldx #WAVEFORM::TRIANGLE
    ldy #BULLET_INIT_VOLUME
    sty bullet_volume
    jmp set_psg_waveform_volume

.endproc

.proc update_bullet_sound

    lda bullet_state
    cmp #BULLET_STATE::PLAYING
    beq playing
    cmp #BULLET_STATE::FADING
    beq fading
    rts

playing:
    sec
    lda bullet_freq
    sbc #BULLET_FREQ_STEP
    sta bullet_freq
    tax
    lda bullet_freq+1
    sbc #0
    sta bullet_freq+1
    tay
    lda #CHANNEL::BULLET
    jmp set_psg_frequency

fading:
    sec
    lda bullet_volume
    sbc #BULLET_VOL_STEP
    sta bullet_volume
    bpl not_done
    stz bullet_state
    stz bullet_volume
not_done:
    lda #CHANNEL::BULLET
    ldx #WAVEFORM::TRIANGLE
    ldy bullet_volume
    jmp set_psg_waveform_volume

.endproc

.proc stop_bullet_sound

    lda #BULLET_STATE::FADING
    sta bullet_state
    rts

.endproc

.proc silence_bullet_sound

    lda #CHANNEL::BULLET
    stz bullet_freq
    stz bullet_volume
    stz bullet_state
    ldy #0
    jsr set_psg_waveform_volume
    rts

.endproc

.proc play_crash_sound

    lda #CRASH_FRAMES
    sta crash_frames
    lda #CHANNEL::CRASH
    ldx #<CRASH_FREQ
    ldy #>CRASH_FREQ
    jsr set_psg_frequency
    lda #CHANNEL::CRASH
    ldx #WAVEFORM::NOISE
    ldy #CRASH_INIT_VOLUME
    sty crash_volume
    jsr set_psg_waveform_volume
    rts

.endproc

.proc update_crash_sound

    lda crash_frames
    bne decrement
    rts

decrement:
    sec
    lda crash_volume
    sbc #CRASH_VOL_STEP
    sta crash_volume
    tay
    ldx #WAVEFORM::NOISE
    lda #CHANNEL::CRASH
    jsr set_psg_waveform_volume
    dec crash_frames
    beq stop_sound
    rts

stop_sound:
    lda #CHANNEL::CRASH
    ldy #0
    jsr set_psg_waveform_volume
    rts

.endproc

.proc play_bonus_sound

    lda #BONUS_FRAMES
    sta bonus_frames

    lda #CHANNEL::BONUS
    ldx #<BONUS_FREQ
    ldy #>BONUS_FREQ
    jsr set_psg_frequency

    lda #CHANNEL::BONUS
    ldx #WAVEFORM::SAWTOOTH
    ldy #BONUS_VOLUME
    jmp set_psg_waveform_volume

.endproc

.proc update_bonus_sound

    lda bonus_frames
    beq done
    dec bonus_frames
    bne done

    lda #CHANNEL::BONUS
    ldy #0
    jmp set_psg_waveform_volume

done:
    rts

.endproc

; A - channel (0-15)
; X - low byte of frequency word
; Y - high byte of frequency word
.proc set_psg_frequency

    jsr get_psg_vram_address
    stz VERA::CTRL
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    ora #(1 << 4)
    sta VERA::ADDR_H

    stx VERA::DATA0
    sty VERA::DATA0

    rts

.endproc

; A - channel (0-15)
; X - waveform (WAVEFORM enum)
; Y - volume (0=silent, 63=max)
.proc set_psg_waveform_volume

    jsr get_psg_vram_address
    stz VERA::CTRL
    clc
    lda vram_addr
    adc #2
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    ora #(1 << 4)
    sta VERA::ADDR_H

    tya
    ora #%11000000
    sta VERA::DATA0

    txa
    ora #%00111111
    sta VERA::DATA0

    rts

.endproc

; A - channel (0-15)
.proc get_psg_vram_address

    asl
    asl
    clc
    adc #<VERA::PSG_VRAM_BASE
    sta vram_addr
    lda #>VERA::PSG_VRAM_BASE
    sta vram_addr+1
    lda #^VERA::PSG_VRAM_BASE
    sta vram_addr+2
    rts

.endproc
