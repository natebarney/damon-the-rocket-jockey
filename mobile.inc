.globalzp mobile_data
.globalzp mobile_ro_data

.global update_mobile_position
.global set_mobile_facing

.global get_cw_direction
.global get_ccw_direction
.global get_reverse_direction

; data related to mobile entities (player, enemies, bullet)
.struct MOBILE
    state   .byte
    dir     .byte
    xpos    .byte
    ypos    .byte
    xvel    .byte
    yvel    .byte
.endstruct

; read-only data related to mobile entities
.struct MOBILE_RO
    sprite      .byte
    palette     .byte
    horiz_ptr   .word
    vert_ptr    .word
    xmin        .byte
    xmax        .byte
    ymin        .byte
    ymax        .byte
    collmask    .byte
.endstruct

; direction enumeration
.enum DIR
    NONE    = 0
    RIGHT   = (1 << 0)
    LEFT    = (1 << 1)
    DOWN    = (1 << 2)
    UP      = (1 << 3)
.endenum

; boundary enumeration
.enum BOUNDARY
    NONE    = 0
    XMAX    = (1 << 0)
    XMIN    = (1 << 1)
    YMAX    = (1 << 2)
    YMIN    = (1 << 3)
.endenum
