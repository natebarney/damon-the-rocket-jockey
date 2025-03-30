.include "kernal.inc"
.include "music.inc"
.include "pcm.inc"

.enum MUSIC_CMD
    STOP    = 0
    NOTE    = 1
    REST    = 2
    RESTART = 3
.endenum

.zeropage

music_ptr: .res 2

.data

music_state: .res 1
current_note: .res 1
music_start: .res 2
music_delay: .res 1
music_type: .res 1
override_mute: .res 1

.code

.proc music_init

    ; swap in audio bank
    lda #$0a
    sta $01

    jsr ym_init

    lda #0
    ldx #$05
    jsr ym_setatten

    lda #MUSIC_STATE::STOPPED
    sta music_state

    stz music_type
    stz override_mute

    rts

.endproc

.proc music_rewind

    lda music_start
    sta music_ptr
    lda music_start+1
    sta music_ptr+1

    stz music_delay
    jmp music_stop

.endproc

.proc music_play

    lda #MUSIC_STATE::PLAYING
    sta music_state
    stz music_delay
    rts

.endproc

.proc music_resume

    lda #MUSIC_STATE::RESUMING
    sta music_state
    rts

.endproc

.proc music_update

    lda music_state
    cmp #MUSIC_STATE::PLAYING
    beq check_delay
    cmp #MUSIC_STATE::RESUMING
    beq resume_note
    rts

resume_note:
    ldx current_note
    cpx #$ff
    beq resume_set_state
    lda #0
    tay
    clc
    jsr ym_playnote
resume_set_state:
    lda #MUSIC_STATE::PLAYING
    sta music_state

check_delay:
    lda music_delay
    beq read_cmd
    dec music_delay
    beq read_cmd
    rts

read_cmd:
    ldy #0
    lda (music_ptr),y
    cmp #MUSIC_CMD::STOP
    beq stop
    cmp #MUSIC_CMD::NOTE
    beq play_note
    cmp #MUSIC_CMD::REST
    beq play_rest
    cmp #MUSIC_CMD::RESTART
    beq restart
    rts

stop:
    lda #MUSIC_STATE::STOPPED
    sta music_state
    rts

restart:
    lda music_start
    sta music_ptr
    lda music_start+1
    sta music_ptr+1
    bra read_cmd

play_note:
    iny
    lda (music_ptr),y
    sta current_note
    tax

    ; if music type is PCM, skip playing this note
    lda music_type
    cmp #MUSIC_TYPE::PCM
    beq read_delay

    ; if music type is FM, play this note
    cmp #MUSIC_TYPE::FM
    beq not_muted

    ; if music_type is FM_MIN, play this note only if override_mute is on
    lda override_mute
    beq read_delay

not_muted:
    phy
    lda #0
    ldy #0
    clc
    jsr ym_playnote
    ply
    bra read_delay

play_rest:
    phy
    lda #$ff ; rest sentinel
    sta current_note
    lda #0
    jsr ym_release
    ply

read_delay:
    iny
    lda (music_ptr),y
    sta music_delay
    iny

    clc
    tya
    adc music_ptr
    sta music_ptr
    lda music_ptr+1
    adc #0
    sta music_ptr+1
    rts

.endproc

.proc music_stop

    lda #MUSIC_STATE::STOPPED
    sta music_state
    lda #0
    jmp ym_release

.endproc

.proc music_load_title

    stz override_mute

    lda #0
    ldx #<music_patch
    ldy #>music_patch
    clc
    jsr ym_loadpatch

    lda #<title_music
    sta music_start
    lda #>title_music
    sta music_start+1
    jmp music_rewind

.endproc

.proc music_load_level

    stz override_mute

    lda #0
    ldx #<music_patch
    ldy #>music_patch
    clc
    jsr ym_loadpatch

    lda #<level_music
    sta music_start
    lda #>level_music
    sta music_start+1
    jmp music_rewind

.endproc

.proc music_load_next_round

    lda #$ff
    sta override_mute

    lda #0
    ldx #<interlude_patch
    ldy #>interlude_patch
    clc
    jsr ym_loadpatch

    lda #<next_round_music
    sta music_start
    lda #>next_round_music
    sta music_start+1
    jmp music_rewind

.endproc

.proc music_load_level_complete

    lda #$ff
    sta override_mute

    lda #0
    ldx #<interlude_patch
    ldy #>interlude_patch
    clc
    jsr ym_loadpatch

    lda #<level_complete_music
    sta music_start
    lda #>level_complete_music
    sta music_start+1
    jmp music_rewind

.endproc

.proc music_cycle_type

    ; increment and wrap music_type
    ldx music_type
    inx
    cpx #MUSIC_TYPE::MAX
    bne not_wrapped
    ldx #$00
not_wrapped:
    stx music_type

    ; handle PCM type
    cpx #MUSIC_TYPE::PCM
    bne not_pcm
    lda #0
    jsr ym_release ; stop FM note
    lda #$08 ; set PCM volume to 8 (about half)
    bra set_volume
not_pcm:
    lda #$00 ; set PCM volume off
set_volume:
    jsr set_pcm_volume

    ; nothing to do for FM type

    ; handle FM_MIN type
    ldx music_type
    cpx #MUSIC_TYPE::FM_MIN
    bne not_fm_min
    lda override_mute
    bne done
    lda #0
    jsr ym_release
not_fm_min:

done:
    rts

.endproc

.rodata

music_patch:
.byte $fc ; $20 - RL / FB / CON
.byte $00 ; $38 - PMS / AMS

;      M1   M2   C1   C2
.byte $01, $01, $01, $31 ; $40 - DT1 / MUL
.byte $19, $1f, $00, $0c ; $60 - TL
.byte $1f, $1f, $16, $16 ; $80 - KS / AR
.byte $16, $16, $0e, $0e ; $A0 - AM-Ena / D1R
.byte $08, $08, $0c, $0c ; $C0 - DT2 / D2R
.byte $00, $00, $cf, $cf ; $E0 - D1L / RR

interlude_patch:
.byte $f4 ; $20 - RL / FB / CON
.byte $00 ; $38 - PMS / AMS

;      M1   M2   C1   C2
.byte $31, $00, $01, $00 ; $40 - DT1 / MUL
.byte $0f, $7f, $00, $7f ; $60 - TL
.byte $1f, $00, $13, $00 ; $80 - KS / AR
.byte $00, $00, $0d, $00 ; $A0 - AM-Ena / D1R
.byte $00, $00, $0c, $00 ; $C0 - DT2 / D2R
.byte $ff, $00, $cf, $00 ; $E0 - D1L / RR

title_music:
level_music:

.byte MUSIC_CMD::NOTE, $1E, 15   ; C2
.byte MUSIC_CMD::NOTE, $1E, 15   ; C2
.byte MUSIC_CMD::NOTE, $21, 15   ; D2
.byte MUSIC_CMD::NOTE, $1E, 15   ; C2
.byte MUSIC_CMD::NOTE, $26, 15   ; F#2
.byte MUSIC_CMD::NOTE, $25, 15   ; F2
.byte MUSIC_CMD::NOTE, $24, 15   ; E2
.byte MUSIC_CMD::NOTE, $25, 15   ; F2
.byte MUSIC_CMD::RESTART

next_round_music:

.byte MUSIC_CMD::NOTE, $3C, 5    ; A#3
.byte MUSIC_CMD::NOTE, $3D, 4    ; B3
.byte MUSIC_CMD::NOTE, $3E, 5    ; C4
.byte MUSIC_CMD::NOTE, $40, 4    ; C#4
.byte MUSIC_CMD::NOTE, $41, 5    ; D4
.byte MUSIC_CMD::NOTE, $42, 4    ; D#4
.byte MUSIC_CMD::NOTE, $44, 5    ; E4
.byte MUSIC_CMD::NOTE, $45, 4    ; F4
.byte MUSIC_CMD::NOTE, $46, 5    ; F#4
.byte MUSIC_CMD::NOTE, $48, 4    ; G4
.byte MUSIC_CMD::STOP

level_complete_music:

.byte MUSIC_CMD::NOTE, $39, 16    ; G#3
.byte MUSIC_CMD::NOTE, $36, 16    ; F#3
.byte MUSIC_CMD::NOTE, $3D, 16    ; B3
.byte MUSIC_CMD::NOTE, $40,  9    ; C#4
.byte MUSIC_CMD::NOTE, $48,  9    ; G4
.byte MUSIC_CMD::NOTE, $42, 16    ; D#4
.byte MUSIC_CMD::NOTE, $40,  9    ; C#4
.byte MUSIC_CMD::NOTE, $48,  9    ; G4
.byte MUSIC_CMD::NOTE, $42, 16    ; D#4
.byte MUSIC_CMD::NOTE, $3D, 16    ; B3
.byte MUSIC_CMD::NOTE, $40, 16    ; C#4
.byte MUSIC_CMD::NOTE, $39, 16    ; G#3
.byte MUSIC_CMD::NOTE, $36, 16    ; F#3
.byte MUSIC_CMD::STOP
