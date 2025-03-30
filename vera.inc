.global copy_ram_to_vram
.global get_l1_tilemap_base
.global get_l1_tileset_base
.global get_l1_tile_address
.global coords_to_vram_addr
.global set_vram_addrs

.globalzp copy_ram_ptr

.global copy_ram_end
.global vram_addr

.global glyphs
.global xcoord
.global ycoord
.global xbegin
.global xend
.global ybegin
.global yend

.scope VERA

; ADDRSEL chooses ADDR0 or ADDR1
ADDR_L := $9f20 ; address bits 0-7
ADDR_M := $9f21 ; address bits 8-15
ADDR_H := $9f22 ; use ADDRH_MASK

.enum ADDRH_MASK
    ADDR_INCR   = %11110000 ; 0=none, 1-10=2^(n-1), 11-15=2^(n-11)*40
    DECR        = %00001000 ; 0=increment, 1=decrement
    NIBBLE_INCR = %00000100
    NIBBLE_ADDR = %00000010
    ADDR16      = %00000001 ; address bit 16
.endenum

DATA0 := $9f23
DATA1 := $9f24
CTRL := $9f25   ; use CTRL_MASK

.enum CTRL_MASK
    RESET   = %10000000
    DCSEL   = %01111110
    ADDRSEL = %00000001
.endenum

IER := $9f26    ; interrupt enable register; use IRQ_MASK
ISR := $9f27    ; interrupt status register; use IRQ_MASK

.enum IRQ_MASK
    COLLISIONS = %11110000  ; sprite collisions; ISR only
    IRQ_LINE8  = %10000000  ; set irq on scan line (bit 8); IER only
    SCAN_LINE8 = %01000000  ; current scan line (bit 8); IER only
    AFLOW      = %00001000  ; audio
    SPRCOL     = %00000100  ; sprite collision
    LINE       = %00000010  ; scan line
    VSYNC      = %00000001  ; vertical sync
.endenum

IRQ_LINE_L := $9f28     ; set irq on scan line (bits 0-7); write-only
SCAN_LINE_L := $9f28    ; current scan line (bits 0-7); read-only

DC_VIDEO := $9f29   ; DCSEL=0, use VID_MASK

.enum VID_MASK
    CUR_FIELD  = %10000000
    SEN        = %01000000  ; sprite layer enable
    L1EN       = %00100000  ; layer 1 enable
    L0EN       = %00010000  ; layer 0 enable
    PROG_SCAN  = %00001000
    CHROMA_DIS = %00000100  ; NTSC only
    HV_SYNC    = %00000100  ; RGB only
    OUT_MODE   = %00000011  ; use VIDEO_MODE
.endenum

.enum VIDEO_MODE
    DISABLED = 0
    VGA = 1
    NTSC = 2
    RGB = 3

.endenum

; scale value shows 128/x logical pixels per physical pixel
DC_HSCALE := $9f2a  ; DCSEL=0
DC_VSCALE := $9f2b  ; DCSEL=0

L0_CONFIG := $9f2d      ; use LAYER_CFG_MASK
L0_MAPBASE := $9f2e     ; address bits 9-16
L0_TILEBASE := $9f2f    ; use TILEBASE_MASK
L0_HSCROLL_L := $9f30
L0_HSCROLL_H := $9f31   ; low nibble
L0_VSCROLL_L := $9f32
L0_VSCROLL_H := $9f33   ; low nibble

L1_CONFIG := $9f34      ; use LAYER_CFG_MASK
L1_MAPBASE := $9f35     ; address bits 9-16
L1_TILEBASE := $9f36    ; use TILEBASE_MASK
L1_HSCROLL_L := $9f37
L1_HSCROLL_H := $9f38   ; low nibble
L1_VSCROLL_L := $9f39
L1_VSCROLL_H := $9f3a   ; low nibble

.enum LAYER_CFG_MASK
    MAP_HEIGHT  = %11000000 ; 0=32 tiles, 1=64 tiles, 2=128 tiles, 3=256 tiles
    MAP_WIDTH   = %00110000 ; 0=32 tiles, 1=64 tiles, 2=128 tiles, 3=256 tiles
    T256C       = %00001000
    BITMAP      = %00000100
    COLOR_DEPTH = %00000011 ; 0=1bpp, 1=2bpp, 2=4bpp, 3=8bpp
.endenum

.enum TILEBASE_MASK
    ADDRESS  = %11111100    ; address bits 11-16
    HEIGHT   = %00000010    ; 0=8 pixels, 1=16 pixels
    WIDTH    = %00000001    ; 0=8 pixels, 1=16 pixels
.endenum

AUDIO_CTRL := $9f3b ; use AUDIO_CTRL_MASK
AUDIO_RATE := $9f3c ; 25 MHz / $10000 * AUDIO_RATE (max 128 -> 48828.125 Hz)
AUDIO_DATA := $9f3d ; audio FIFO data (write-only)

.enum AUDIO_CTRL_MASK
    FIFO_FULL    = %10000000    ; read-only
    FIFO_RESET   = %10000000    ; write-only
    FIFO_LOOP    = %11000000    ; write-only
    SAMPLE_16BIT = %00100000    ; 0=8-bit, 1=16-bit (two's complement signed)
    STEREO       = %00010000    ; 0=mono, 1=stereo
    VOLUME       = %00001111    ; 0=silent, 15=max (logarithmic)
.endenum

PSG_VRAM_BASE = $1f9c0
SPRITE_ATTR_VRAM = $1FC00
SPRITE_DATA_VRAM = $13000
PALETTE_VRAM = $1fa00

.endscope
