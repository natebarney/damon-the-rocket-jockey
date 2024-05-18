.global update_animation

.globalzp animation_data_ptr

; data related to mobile entities (player, enemies, bullet)
.struct ANIM_DATA
    table   .addr
    delay   .byte
    sprite  .byte
.endstruct

.enum ANIM_CMD
    STOP      =  0
    BREAK     =  1
    JUMP      =  2
    DELAY     =  3
    ENABLE    =  4
    DISABLE   =  5
    IMAGE     =  6
    SIZE      =  7
    POS       =  8
    RELPOS    =  9
    FLIP      = 10
    PALETTE   = 11
    COLL_MASK = 12
.endenum
