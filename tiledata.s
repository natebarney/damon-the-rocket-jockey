.include "tiledata.inc"

.rodata

letter_tile_data:

; $00: Copyright symbol
.byte %00111100
.byte %01000010
.byte %10011101
.byte %10100001
.byte %10100001
.byte %10011101
.byte %01000010
.byte %00111100

; $01: A
.byte %00000000
.byte %00011100
.byte %00110010
.byte %01110010
.byte %01111110
.byte %01110010
.byte %00110010
.byte %00010010

; $02: B
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110010
.byte %01111100
.byte %01110010
.byte %01110010
.byte %00111100

; $03: C
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110000
.byte %01110000
.byte %01110000
.byte %01110010
.byte %00111100

; $04: D
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01111100

; $05: E
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110000
.byte %01111100
.byte %01110000
.byte %01110010
.byte %00111100

; $06: F
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110000
.byte %01111100
.byte %01110000
.byte %01110000
.byte %00110000

; $07: G
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110000
.byte %01110110
.byte %01110010
.byte %01110010
.byte %00111100

; $08: H
.byte %00000000
.byte %00110010
.byte %01110010
.byte %01110010
.byte %01111110
.byte %01110010
.byte %01110010
.byte %00110010

; $09: I
.byte %00000000
.byte %01111110
.byte %00111000
.byte %00111000
.byte %00111000
.byte %00111000
.byte %00111000
.byte %01111110

; $0A: J (guessed)
.byte %00000000
.byte %00111110
.byte %00001100
.byte %00001110
.byte %00001110
.byte %00001110
.byte %01001110
.byte %00111100

; $0B: K
.byte %00000000
.byte %00110110
.byte %01110110
.byte %01110100
.byte %01111000
.byte %01110100
.byte %01110110
.byte %00110110

; $0C: L
.byte %00000000
.byte %00110000
.byte %01110000
.byte %01110000
.byte %01110000
.byte %01110000
.byte %01110010
.byte %00111100

; $0D: M
.byte %00000000
.byte %00110110
.byte %01110110
.byte %01110110
.byte %01101010
.byte %01100010
.byte %01100010
.byte %00100010

; $0E: N
.byte %00000000
.byte %00110011
.byte %01111011
.byte %01110111
.byte %01110011
.byte %01110011
.byte %01110011
.byte %00110011

; $0F: O
.byte %00000000
.byte %00111110
.byte %01100110
.byte %01100110
.byte %01100110
.byte %01100110
.byte %01100110
.byte %00111110

; $10: P
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110010
.byte %01111100
.byte %01110000
.byte %01110000
.byte %00110000

; $11: Q
.byte %00000000
.byte %00111110
.byte %01111110
.byte %01100010
.byte %01100010
.byte %01100110
.byte %01111100
.byte %00111011

; $12: R
.byte %00000000
.byte %00111100
.byte %01110011
.byte %01110011
.byte %01111100
.byte %01111100
.byte %01110011
.byte %00110011

; $13: S
.byte %00000000
.byte %00111100
.byte %01110010
.byte %01110000
.byte %01111110
.byte %00001110
.byte %01001110
.byte %00111100

; $14: T
.byte %00000000
.byte %01111110
.byte %00111000
.byte %00111000
.byte %00111000
.byte %00111000
.byte %00111000
.byte %00111000

; $15: U
.byte %00000000
.byte %00110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %00111110

; $16: V
.byte %00000000
.byte %00110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %01111110
.byte %00111100

; $17: W (guessed)
.byte %00000000
.byte %00100010
.byte %01100010
.byte %01100010
.byte %01101010
.byte %01110110
.byte %01110110
.byte %00110110

; $18: X (guessed)
.byte %00000000
.byte %01110110
.byte %01110110
.byte %00110100
.byte %00011000
.byte %00110100
.byte %01110110
.byte %01110110

; $19: Y
.byte %00000000
.byte %00110010
.byte %01110010
.byte %01110010
.byte %01110010
.byte %00111110
.byte %00011000
.byte %00011000

; $1A: Z (guessed)
.byte %00000000
.byte %01111110
.byte %00001110
.byte %00011100
.byte %00111000
.byte %01110000
.byte %01110000
.byte %01111110

letter_tile_data_end:

number_tile_data:

; $30: 0
.byte %00000000
.byte %00111100
.byte %01111110
.byte %01100010
.byte %01100010
.byte %01100010
.byte %01111110
.byte %00111100

; $31: 1
.byte %00000000
.byte %00011100
.byte %00111100
.byte %01111100
.byte %00011100
.byte %00011100
.byte %00011100
.byte %01111110

; $32: 2
.byte %00000000
.byte %01111100
.byte %01000110
.byte %00000110
.byte %01111110
.byte %01100000
.byte %01111110
.byte %00111100

; $33: 3
.byte %00000000
.byte %01111100
.byte %01001110
.byte %00001110
.byte %00111110
.byte %00001110
.byte %01001110
.byte %01111100

; $34: 4
.byte %00000000
.byte %00111100
.byte %01011100
.byte %10011100
.byte %11111110
.byte %01111110
.byte %00011100
.byte %00011100

; $35: 5
.byte %00000000
.byte %01111110
.byte %01100010
.byte %01100000
.byte %01111110
.byte %00000110
.byte %01111110
.byte %00111100

; $36: 6
.byte %00000000
.byte %00111110
.byte %01111110
.byte %01110000
.byte %01111110
.byte %01110010
.byte %01110010
.byte %00111100

; $37: 7
.byte %00000000
.byte %01111110
.byte %00001110
.byte %00001110
.byte %00011100
.byte %00111000
.byte %00111000
.byte %00111000

; $38: 8
.byte %00000000
.byte %00111100
.byte %01100110
.byte %01111110
.byte %00111100
.byte %01100110
.byte %01111110
.byte %00111100

; $39: 9
.byte %00000000
.byte %01111100
.byte %01001110
.byte %01001110
.byte %01111110
.byte %00001110
.byte %01111110
.byte %00111100

; $3A: : (guessed)
.byte %00000000
.byte %00000000
.byte %00100000
.byte %00110000
.byte %00000000
.byte %00100000
.byte %00110000
.byte %00000000

number_tile_data_end:

graphic_tile_data:

; $80: Border segment corner top-left
.byte %00000000
.byte %00000000
.byte %00001111
.byte %00011111
.byte %00011111
.byte %00111111
.byte %00111100
.byte %00111100

; $81: Border segment corner top-right
.byte %00000000
.byte %00000000
.byte %11110000
.byte %11111000
.byte %11111000
.byte %11111100
.byte %00111100
.byte %00111100

; $82: Border segment corner bottom-left
.byte %00111100
.byte %00111100
.byte %00111111
.byte %00011111
.byte %00011111
.byte %00001111
.byte %00000000
.byte %00000000

; $83: Border segment corner bottom-right
.byte %00111100
.byte %00111100
.byte %11111100
.byte %11111000
.byte %11111000
.byte %11110000
.byte %00000000
.byte %00000000

; $84: Border segment vertical
.byte %00111100
.byte %00111100
.byte %00111100
.byte %00111100
.byte %00111100
.byte %00111100
.byte %00111100
.byte %00111100

; $85: Border segment horizontal
.byte %00000000
.byte %00000000
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %00000000
.byte %00000000

; $86: Border segment t-junction
.byte %00000000
.byte %00000000
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %00111100
.byte %00111100

; $87: Border segment inverted t-junction
.byte %00111100
.byte %00111100
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %00000000
.byte %00000000

; $88: Pellet top-left
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000001
.byte %00000011

tile_period:
; $89: Pellet top-right
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %10000000
.byte %11000000
tile_period_end:

tile_backtick:
; $8A: Pellet bottom-left
.byte %00000011
.byte %00000001
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
tile_backtick_end:

tile_apostrophe:
; $8B: Pellet bottom-right
.byte %11000000
.byte %10000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
tile_apostrophe_end:

; $8C: Barrier block
.byte %00000000
.byte %01111110
.byte %01111110
.byte %00111100
.byte %00111100
.byte %01111110
.byte %01111110
.byte %00000000

; $8D: Level 1 block top-left
.byte %11111111
.byte %11111111
.byte %11000000
.byte %11011111
.byte %11011111
.byte %11011000
.byte %11011011
.byte %11011011

; $8E: Level 1 block top-right
.byte %11111111
.byte %11111111
.byte %00000011
.byte %11111011
.byte %11111011
.byte %00011011
.byte %11011011
.byte %11011011

; $8F: Level 1 block bottom-left
.byte %11011011
.byte %11011011
.byte %11011000
.byte %11011111
.byte %11011111
.byte %11000000
.byte %11111111
.byte %11111111

; $90: Level 1 block bottom-right
.byte %11011011
.byte %11011011
.byte %11011011
.byte %11011011
.byte %11011011
.byte %00011011
.byte %11111011
.byte %11111011

; $91: Level 2 block
.byte %00011000
.byte %00100100
.byte %01000010
.byte %10000001
.byte %10000001
.byte %01000010
.byte %00100100
.byte %00011000

; $92: Level 3 block
.byte %00011000
.byte %00011000
.byte %00111100
.byte %11111111
.byte %11111111
.byte %00111100
.byte %00011000
.byte %00011000

; $93: Level 4 block
.byte %00011000
.byte %01111110
.byte %00000000
.byte %11111111
.byte %11111111
.byte %00000000
.byte %01111110
.byte %00011000

; $94: Level 5 block top-left
.byte %00000111
.byte %00011111
.byte %00111111
.byte %01111111
.byte %01111111
.byte %11111111
.byte %11111100
.byte %11111100

; $95: Level 5 block top-right
.byte %11100000
.byte %11111000
.byte %11111100
.byte %11111110
.byte %11111110
.byte %11111111
.byte %00111111
.byte %00111111

; $96: Level 5 block bottom-left
.byte %11111100
.byte %11111100
.byte %11111111
.byte %01111111
.byte %01111111
.byte %00111111
.byte %00011111
.byte %00000111

; $97: Level 5 block bottom-right
.byte %00111111
.byte %00111111
.byte %11111111
.byte %11111110
.byte %11111110
.byte %11111100
.byte %11111000
.byte %11100000

graphic_tile_data_end:
