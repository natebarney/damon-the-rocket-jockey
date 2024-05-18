.globalzp sprite_collisions

.global enemy_rect
.global other_rect

.global check_enemy_collision

.enum COLL_MASK
    NONE          = %00000000
    PLAYER        = %00010000
    PLAYER_BULLET = %00100000
    ENEMY_BULLET  = %01000000
.endenum

.struct RECT
    xmin    .byte
    ymin    .byte
    xmax    .byte
    ymax    .byte
.endstruct
