.include "vera.inc"

.zeropage

copy_ram_ptr: .res 2

.data

vram_addr: .res 3
copy_ram_end: .res 2
offset: .res 3

glyphs: .res 4
xbegin: .res 1
xend: .res 1
ybegin: .res 1
yend: .res 1
xcoord: .res 1
ycoord: .res 1

.code

; copy data from ram to vram
;
; copy_ram_ptr - source ram address
; copy_ram_end - source ram end address
; vram_addr    - destination vram address
.proc copy_ram_to_vram

    ; set vera address pointer 0 to vram_addr with 1-byte increment
    stz VERA::CTRL                  ; set ADDRSEL to 0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    and #VERA::ADDRH_MASK::ADDR16   ; mask off all but address high bit
    ora #(1 << 4)                   ; set address increment to 1
    sta VERA::ADDR_H

    ; copy data
    ldy #0
copy_loop:

    lda (copy_ram_ptr),y
    sta VERA::DATA0

    ; increment copy_ram_ptr
    inc copy_ram_ptr
    bne nocarry
    inc copy_ram_ptr+1
nocarry:

    ; if copy_ram_ptr < copy_ram_end, go to top of loop
    lda copy_ram_end+1
    cmp copy_ram_ptr+1
    beq compare_low
    bcs copy_loop
compare_low:
    lda copy_ram_end
    cmp copy_ram_ptr
    bcc copy_done
    bne copy_loop

copy_done:
    rts

.endproc

.proc shift_vram_addr_left

loop:
    asl vram_addr
    rol vram_addr+1
    rol vram_addr+2
    dex
    bne loop

    rts

.endproc

; set vram_addr to tileset base address
.proc get_l1_tileset_base

    ; load tileset base address and mask of tile size bits
    lda VERA::L1_TILEBASE
    and #<(~(VERA::TILEBASE_MASK::HEIGHT | VERA::TILEBASE_MASK::WIDTH))

    ; store tileset base address into vram_addr
    sta vram_addr
    stz vram_addr+1
    stz vram_addr+2

    ; shift vram_addr left 9 bits
    ldx #9
    jmp shift_vram_addr_left

.endproc

; set vram_addr to tilemap base address
.proc get_l1_tilemap_base

    ; load tilemap base address
    lda VERA::L1_MAPBASE

    ; store tilemap base address into vram_addr
    sta vram_addr
    stz vram_addr+1
    stz vram_addr+2

    ; shift vram_addr left 9 bits
    ldx #9
    jmp shift_vram_addr_left

.endproc

; get vram address of tile index into vram_addr
; tile index in accumulator
.proc get_l1_tile_address

    ; get tileset base address into vram_addr
    pha
    jsr get_l1_tileset_base
    pla

    ; set offset to tile index* 8
    sta offset
    stz offset+1
    stz offset+2
    ldx #3 ; counter to shift offset left 3 bits
shift_loop:
    asl offset
    rol offset+1
    rol offset+2
    dex
    bne shift_loop

    ; vram_addr += offset
    clc
    ldx #0
addition_loop:
    lda vram_addr,x
    adc offset,x
    sta vram_addr,x
    inx
    cpx #3
    bne addition_loop

    rts

.endproc

; compute the vram address of a tile map entry, given coordinates
;
; xcoord - top-left column
; ycoord - top-left row
; vram_addr - computed vram address
.proc coords_to_vram_addr

    ; get tilemap base address into vram_addr
    jsr get_l1_tilemap_base

    ; offset = ycoord
    lda ycoord
    sta offset
    stz offset+1
    stz offset+2

    ; shift offset left by 6
    ldx #6
loop1:
    asl offset
    rol offset+1
    rol offset+2
    dex
    bne loop1

    ; offset += xcoord
    clc
    lda offset
    adc xcoord
    sta offset
    lda offset+1
    adc #0
    sta offset+1
    lda offset+2
    adc #0
    sta offset+2

    ; shift offset left by 1
    asl offset
    rol offset+1
    rol offset+2

    ; vram_addr += offset
    clc
    lda vram_addr
    adc offset
    sta vram_addr
    lda vram_addr+1
    adc offset+1
    sta vram_addr+1
    lda vram_addr+2
    adc offset+2
    sta vram_addr+2

    rts

.endproc

; set vera address pointers to vram_addr and vram_addr+1 with 2-byte increment
.proc set_vram_addrs

    ; set vera address pointer 0 to vram_addr with 2-byte increment
    stz VERA::CTRL                  ; set ADDRSEL to 0
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    and #VERA::ADDRH_MASK::ADDR16   ; mask off all but address high bit
    ora #(2 << 4)                   ; set address increment to 2
    sta VERA::ADDR_H

    ; tilemap base is even so this won't carry
    inc vram_addr

    ; set vera address pointer 1 to vram_addr with 2-byte increment
    lda #VERA::CTRL_MASK::ADDRSEL
    sta VERA::CTRL                  ; set ADDRSEL to 1
    lda vram_addr
    sta VERA::ADDR_L
    lda vram_addr+1
    sta VERA::ADDR_M
    lda vram_addr+2
    and #VERA::ADDRH_MASK::ADDR16   ; mask off all but address high bit
    ora #(2 << 4)                   ; set address increment to 2
    sta VERA::ADDR_H

    ; restore vram_addr
    dec vram_addr

    rts

.endproc
