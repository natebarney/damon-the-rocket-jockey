.include "pcm.inc"
.include "kernal.inc"
.include "vera.inc"

BANK_CTRL := $00
BANK_ADDR := $A000
BANK_SIZE := $2000
BANK_END := BANK_ADDR + BANK_SIZE
BANK_LAST := BANK_END - 1
INITIAL_BANK = $01

.struct CLIP_RO
    filename        .addr
    filename_len    .byte
.endstruct

.struct CLIP
    begin_addr      .addr
    begin_bank      .byte
    end_addr        .addr
    end_bank        .byte
    size            .word
.endstruct

.enum PCM_INSTR
    STOP        = 0
    PLAY        = 1
    JUMP        = 2
    TRACE_ON    = 3
    TRACE_OFF   = 4
    RESTORE     = 5
.endenum

.macro define_clip LBL, VAL
.ident(.concat("fname_", LBL)):
.byte VAL
.ident(.concat("fname_", LBL, "_len")) = * - .ident(.concat("fname_", LBL))
.endmacro

clip_counter .set 0

.macro reference_clip LBL
.addr .ident(.concat("fname_", LBL))
.byte .ident(.concat("fname_", LBL, "_len"))
.ident(.concat("c_", LBL)) = clip_counter
clip_counter .set clip_counter + 1
.endmacro

.rodata

    define_clip "bassline", "BASSLINE.PCM"
    define_clip "complete", "COMPLETE.PCM"
    define_clip "melody1", "MELODY1.PCM"
    define_clip "melody2", "MELODY2.PCM"
    define_clip "melody3", "MELODY3.PCM"
    define_clip "melody4", "MELODY4.PCM"
    define_clip "melody5", "MELODY5.PCM"
    define_clip "melody6", "MELODY6.PCM"
    define_clip "melody7", "MELODY7.PCM"
    define_clip "melody8", "MELODY8.PCM"
    define_clip "slide", "SLIDE.PCM"
    define_clip "stab1", "STAB1.PCM"
    define_clip "stab2", "STAB2.PCM"
    define_clip "start", "START.PCM"

clips_ro:
    reference_clip "bassline"
    reference_clip "complete"
    reference_clip "melody1"
    reference_clip "melody2"
    reference_clip "melody3"
    reference_clip "melody4"
    reference_clip "melody5"
    reference_clip "melody6"
    reference_clip "melody7"
    reference_clip "melody8"
    reference_clip "slide"
    reference_clip "stab1"
    reference_clip "stab2"
    reference_clip "start"
clip_count = (* - clips_ro) / .sizeof(CLIP_RO)

clips_melody:
clips_melody_odd:
.repeat 2
    .byte PCM_INSTR::PLAY, c_melody1
    .byte PCM_INSTR::PLAY, c_melody2
    .byte PCM_INSTR::PLAY, c_melody1
    .byte PCM_INSTR::PLAY, c_melody3
    .byte PCM_INSTR::PLAY, c_melody1
    .byte PCM_INSTR::PLAY, c_melody2
    .byte PCM_INSTR::PLAY, c_melody1
    .byte PCM_INSTR::PLAY, c_melody4
.endrep
.repeat 4
    .byte PCM_INSTR::PLAY, c_bassline
.endrep
clips_melody_even:
.repeat 2
    .byte PCM_INSTR::PLAY, c_melody5
    .byte PCM_INSTR::PLAY, c_melody6
    .byte PCM_INSTR::PLAY, c_melody5
    .byte PCM_INSTR::PLAY, c_melody7
    .byte PCM_INSTR::PLAY, c_melody5
    .byte PCM_INSTR::PLAY, c_melody6
    .byte PCM_INSTR::PLAY, c_melody5
    .byte PCM_INSTR::PLAY, c_melody8
.endrep
.repeat 4
    .byte PCM_INSTR::PLAY, c_bassline
.endrep
.byte PCM_INSTR::JUMP
.addr clips_melody

clips_title:
.byte PCM_INSTR::TRACE_OFF
.byte PCM_INSTR::PLAY, c_slide
.byte PCM_INSTR::PLAY, c_bassline
.byte PCM_INSTR::PLAY, c_bassline
.byte PCM_INSTR::PLAY, c_stab1
.byte PCM_INSTR::PLAY, c_bassline
.byte PCM_INSTR::PLAY, c_stab2
.byte PCM_INSTR::PLAY, c_bassline
.byte PCM_INSTR::JUMP
.addr clips_melody

clips_start_odd:
.byte PCM_INSTR::PLAY, c_start
.byte PCM_INSTR::TRACE_ON
.byte PCM_INSTR::JUMP
.addr clips_melody_odd

clips_start_even:
.byte PCM_INSTR::PLAY, c_start
.byte PCM_INSTR::TRACE_ON
.byte PCM_INSTR::JUMP
.addr clips_melody_even

clips_death:
.byte PCM_INSTR::TRACE_OFF
.byte PCM_INSTR::STOP

clips_respawn:
.byte PCM_INSTR::TRACE_OFF
.byte PCM_INSTR::PLAY, c_start
.byte PCM_INSTR::TRACE_ON
.byte PCM_INSTR::RESTORE

clips_complete:
.byte PCM_INSTR::TRACE_OFF
.byte PCM_INSTR::PLAY, c_complete
.byte PCM_INSTR::STOP

.data

clips: .res .sizeof(CLIP) * clip_count
playing: .res 1
next_bank: .res 1
samples_remaining: .res 2
saved_instr: .res 2
tracing: .res 1
volume: .res 1

.zeropage

clip_ro_ptr: .res 2
clip_ptr: .res 2
next_addr: .res 2
instr_ptr = clip_ro_ptr ; reuse ZP storage, symbols are not used simultaneously

.code

.proc init_pcm

    ; set saved_instr to #clips_melody
    lda #<clips_melody
    sta saved_instr
    lda #>clips_melody
    sta saved_instr+1

    ; clear tracing flag
    stz tracing

    ; initial volume to 8/15
    lda #$08
    sta volume

    ; intentional fallthrough to stop_pcm

.endproc

.proc stop_pcm

    ; stop PCM playback
    stz VERA::AUDIO_RATE

    ; clear playing flag
    stz playing

    ; clear FIFO buffer
    lda #VERA::AUDIO_CTRL_MASK::FIFO_RESET
    sta VERA::AUDIO_CTRL

    rts

.endproc

.proc load_clips

    ; start at clip 0
    ldx #$00

    ; initialize clip_ro_ptr
    lda #<clips_ro
    sta clip_ro_ptr
    lda #>clips_ro
    sta clip_ro_ptr+1

    ; initialize clip_ptr
    lda #<clips
    sta clip_ptr
    lda #>clips
    sta clip_ptr+1

    ; set initial address to BANK_ADDR
    ldy #CLIP::begin_addr
    lda #<BANK_ADDR
    sta (clip_ptr),y
    iny
    lda #>BANK_ADDR
    sta (clip_ptr),y

    ; set initial bank to INITIAL_BANK
    ldy #CLIP::begin_bank
    lda #INITIAL_BANK
    sta (clip_ptr),y

loop:
    ; load the clip
    phx
    jsr load_clip
    plx
    bcs error

    ; copy loaded clip's end address and bank to next_addr and next_bank
    ldy #CLIP::end_addr
    lda (clip_ptr),y
    sta next_addr
    iny
    lda (clip_ptr),y
    sta next_addr+1
    ldy #CLIP::end_bank
    lda (clip_ptr),y
    sta next_bank

    ; increment clip index and see if we're done
    inx
    cpx #clip_count
    beq done

    ; not done, so advance clip_ro_ptr and clip_ptr
    clc
    lda clip_ro_ptr
    adc #<.sizeof(CLIP_RO)
    sta clip_ro_ptr
    lda clip_ro_ptr+1
    adc #>.sizeof(CLIP_RO)
    sta clip_ro_ptr+1

    clc
    lda clip_ptr
    adc #<.sizeof(CLIP)
    sta clip_ptr
    lda clip_ptr+1
    adc #>.sizeof(CLIP)
    sta clip_ptr+1

    ; copy last clip's end to next clip's begin
    ldy #CLIP::begin_addr
    lda next_addr
    sta (clip_ptr),y
    iny
    lda next_addr+1
    sta (clip_ptr),y
    ldy #CLIP::begin_bank
    lda next_bank
    sta (clip_ptr),y

    ; load next clip
    bra loop

done:
    clc
error:
    rts

.endproc

.proc print_clip_filename

    ; load pointer to filename in next_addr (used because it's available)
    ldy #CLIP_RO::filename
    lda (clip_ro_ptr),y
    sta next_addr
    iny
    lda (clip_ro_ptr),y
    sta next_addr+1

    ; load filename_len into samples_remaining (used because it's available)
    ldy #CLIP_RO::filename_len
    lda (clip_ro_ptr),y
    sta samples_remaining

    ; print out string
    ldy #$00
loop:
    cpy samples_remaining
    beq done
    lda (next_addr),y
    jsr BSOUT
    iny
    bra loop

done:

    ; output a space
    lda #' '
    jsr BSOUT

    rts

.endproc

.proc load_clip

    ; set .X and .Y to point to current filename
    ldy #CLIP_RO::filename
    lda (clip_ro_ptr),y
    tax
    iny
    lda (clip_ro_ptr),y
    tay

    ; set .A to point to current filename len
    phy
    ldy #CLIP_RO::filename_len
    lda (clip_ro_ptr),y
    ply

    ; set the filename to load in the kernal
    jsr SETNAM

    ; set load parameters
    lda #$01    ; logical file number
    ldx #$08    ; device number
    ldy #$02    ; headerless load
    jsr SETLFS

    jsr print_clip_filename

    ; select the the clip's begin_bank
    ldy #CLIP::begin_bank
    lda (clip_ptr),y
    sta BANK_CTRL

    ; set .X and .Y to the clip's begin_address
    ldy #CLIP::begin_addr
    lda (clip_ptr),y
    tax
    iny
    lda (clip_ptr),y
    tay

    ; load clip into RAM using kernal routine
    lda #$00    ; load into system memory
    jsr LOAD
    bcs error

    ; save end address (save high byte first so we can use .Y)
    tya
    ldy #CLIP::end_addr+1
    sta (clip_ptr),y
    dey
    txa
    sta (clip_ptr),y

    ; save end bank
    ldy #CLIP::end_bank
    lda BANK_CTRL
    sta (clip_ptr),y

    ; print success character
    lda #$71 ; filled circle
    jsr BSOUT
    lda #$0d ; carriage return
    jsr BSOUT

    jsr calc_clip_size
    clc ; carry clear indicates success
    rts

error:
    ; print failure character
    lda #$76 ; diagonal cross
    jsr BSOUT
    lda #$0d ; carriage return
    jsr BSOUT

    sec ; carry set indicates failure
    rts

.endproc

.proc calc_clip_size

    ; if begin and end banks are equal, the size is just end addr - begin addr
    ldy #CLIP::begin_bank
    lda (clip_ptr),y
    ldy #CLIP::end_bank
    cmp (clip_ptr),y
    bne different_banks

    sec
    ldy #CLIP::end_addr
    lda (clip_ptr),y
    ldy #CLIP::begin_addr
    sbc (clip_ptr),y
    ldy #CLIP::size
    sta (clip_ptr),y
    ldy #CLIP::end_addr+1
    lda (clip_ptr),y
    ldy #CLIP::begin_addr+1
    sbc (clip_ptr),y
    ldy #CLIP::size+1
    sta (clip_ptr),y
    rts

different_banks:

    ; the size in the first bank only is BANK_END - begin_addr
    sec
    lda #<BANK_END
    ldy #CLIP::begin_addr
    sbc (clip_ptr),y
    ldy #CLIP::size
    sta (clip_ptr),y
    lda #>BANK_END
    ldy #CLIP::begin_addr+1
    sbc (clip_ptr),y
    ldy #CLIP::size+1
    sta (clip_ptr),y

    ; the size in the last bank is end_addr - BANK_ADDR
    ; add end_addr to size, then subtract BANK_ADDR from the new size
    clc
    ldy #CLIP::end_addr
    lda (clip_ptr),y
    ldy #CLIP::size
    adc (clip_ptr),y
    sta (clip_ptr),y
    ldy #CLIP::end_addr+1
    lda (clip_ptr),y
    ldy #CLIP::size+1
    adc (clip_ptr),y
    sta (clip_ptr),y

    sec
    ldy #CLIP::size
    lda (clip_ptr),y
    sbc #<BANK_ADDR
    sta (clip_ptr),y
    iny
    lda (clip_ptr),y
    sbc #>BANK_ADDR
    sta (clip_ptr),y

    ; all that's remaining now is full banks, end_bank - begin_bank - 1 of them

    ; get number of full banks into .X
    sec
    ldy #CLIP::end_bank
    lda (clip_ptr),y
    ldy #CLIP::begin_bank
    sbc (clip_ptr),y
    tax
    dex
    beq done ; no full banks

    ; add BANK_SIZE to size .X times
loop:
    clc
    ldy #CLIP::size
    lda #<BANK_SIZE
    adc (clip_ptr),y
    sta (clip_ptr),y
    iny
    lda #>BANK_SIZE
    adc (clip_ptr),y
    sta (clip_ptr),y
    dex
    bne loop

done:
    rts

.endproc

.proc select_next_clip

    ; get interpreter instruction
    ldy #0
    lda (instr_ptr),y

    ; handle STOP instruction
    bne not_stop
    stz playing
    rts
not_stop:

    ; handle PLAY instruction
    cmp #PCM_INSTR::PLAY
    bne not_play
    bit tracing
    bpl not_tracing
    lda instr_ptr
    sta saved_instr
    lda instr_ptr+1
    sta saved_instr+1
not_tracing:
    iny
    lda (instr_ptr),y
    pha
    clc
    lda instr_ptr
    adc #<$0002
    sta instr_ptr
    lda instr_ptr+1
    adc #>$0002
    sta instr_ptr+1
    pla
    jmp calc_clip_ptr
not_play:

    ; handle JUMP instruction
    cmp #PCM_INSTR::JUMP
    bne not_jump
    iny
    lda (instr_ptr),y
    pha
    iny
    lda (instr_ptr),y
    sta instr_ptr+1
    pla
    sta instr_ptr
    bra select_next_clip
not_jump:

    ; handle TRACE_ON instruction
    cmp #PCM_INSTR::TRACE_ON
    bne not_trace_on
    lda #$FF
    sta tracing
    bra skip
not_trace_on:

    ; handle TRACE_OFF instruction
    cmp #PCM_INSTR::TRACE_OFF
    bne not_trace_off
    stz tracing
    bra skip
not_trace_off:

    ; handle RESTORE instruction
    cmp #PCM_INSTR::RESTORE
    bne not_restore
    lda saved_instr
    sta instr_ptr
    lda saved_instr+1
    sta instr_ptr+1
    bra select_next_clip
not_restore:

    ; unknown instruction so skip
skip:
    inc instr_ptr
    bne select_next_clip
    inc instr_ptr+1
    bra select_next_clip

.endproc

; clip index in .A
.proc calc_clip_ptr

    ; store clip index in samples_remaining and multiply by 8 (sizeof(CLIP))
    ;
    ; (use samples_remaining because it's unused in this part of the code, and
    ; it saves allocating another variable)
.assert .sizeof(CLIP) = 8, error, "Code assumes sizeof(CLIP) == 8"
    sta samples_remaining
    stz samples_remaining+1
    asl samples_remaining
    rol samples_remaining+1
    asl samples_remaining
    rol samples_remaining+1
    asl samples_remaining
    rol samples_remaining+1

    ; add computed offset to clip_ptr
    clc
    lda #<clips
    adc samples_remaining
    sta clip_ptr
    lda #>clips
    adc samples_remaining+1
    sta clip_ptr+1

    ; point next_bank:next_addr to begin_bank:begin_addr
    ldy #CLIP::begin_addr
    lda (clip_ptr),y
    sta next_addr
    iny
    lda (clip_ptr),y
    sta next_addr+1
    ldy #CLIP::begin_bank
    lda (clip_ptr),y
    sta next_bank

    ; copy clip's size to samples_remaining
    ldy #CLIP::size
    lda (clip_ptr),y
    sta samples_remaining
    iny
    lda (clip_ptr),y
    sta samples_remaining+1

    rts

.endproc

; expects address of first instruction in .X (low byte) and .Y (high byte)
.proc start_pcm

    ; save passed-in instruction pointer
    stx instr_ptr
    sty instr_ptr+1

    ; stop current playback and set playing flag to true
    jsr stop_pcm
    lda #$FF
    sta playing

    ; execute interpreter instructions until we have another clip or a STOP
    jsr select_next_clip

    ; if last instruction was STOP, we're done
    bit playing
    bpl done

    ; make sure FIFO is filled before turning on PCM playback
    jsr fill_fifo

    ; start PCM playback
    lda volume
    and #VERA::AUDIO_CTRL_MASK::VOLUME ; mono, 8-bit
    sta VERA::AUDIO_CTRL
    lda #$15                ; about 8010.86 Hz
    sta VERA::AUDIO_RATE

done:
    rts

.endproc

.proc fill_fifo

    ; save bank register
    lda BANK_CTRL
    pha

    ; go to next_bank
    lda next_bank
    sta BANK_CTRL

    ; set y index to 0 for indirect indexed addressing
    ldy #$00

loop:
    ; if FIFO is full, jump to done
    bit VERA::AUDIO_CTRL
    bmi done

    ; if we're out of samples in this clip, get the next clip
    lda samples_remaining
    ora samples_remaining+1
    beq next_clip

    ; copy next byte to FIFO
    lda (next_addr),y
    sta VERA::AUDIO_DATA

    ; increment low byte of pointer
    inc next_addr
    bne dec_samples

    ; increment high byte of pointer
    lda next_addr+1
    cmp #>BANK_LAST
    beq bank_wrap
    clc
    adc #$01
    sta next_addr+1
    bra dec_samples

    ; increment bank byte of pointer
bank_wrap:
    lda #>BANK_ADDR ; wrap next_addr back to BANK_ADDR
    sta next_addr+1
    inc next_bank   ; increment next_bank and bank register
    inc BANK_CTRL

    ; decrement samples_remaining and then jump to the top of the loop
dec_samples:
    sec
    lda samples_remaining
    sbc #<$0001
    sta samples_remaining
    lda samples_remaining+1
    sbc #>$0001
    sta samples_remaining+1
    bra loop

next_clip:
    ; we're at the end of the buffer, so go to the next clip
    jsr select_next_clip
    bit playing
    bpl done

    ; update the hardware bank register as next_bank might have changed
    lda next_bank
    sta BANK_CTRL

    bra loop

done:

    ; restore bank register
    pla
    sta BANK_CTRL

    rts

.endproc

; volume in .A
.proc set_pcm_volume

    and #VERA::AUDIO_CTRL_MASK::VOLUME ; mono, 8-bit
    sta volume
    sta VERA::AUDIO_CTRL
    rts

.endproc
