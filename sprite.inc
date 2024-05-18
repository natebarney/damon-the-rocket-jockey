.global load_sprites

.global set_sprite_image
.global set_sprite_pos
.global get_sprite_pos
.global set_sprite_collision_mask
.global sprite_enable
.global sprite_disable
.global set_sprite_flip
.global set_sprite_size
.global set_sprite_palette_offset
.global reset_sprites

.global sprite_data_ptr

.global PLAYER_BULLET_H_SPRITE_PTR
.global PLAYER_BULLET_V_SPRITE_PTR
.global ENEMY_BULLET_H_SPRITE_PTR
.global ENEMY_BULLET_V_SPRITE_PTR
.global PLAYER_H_SPRITE_PTR
.global PLAYER_V_SPRITE_PTR
.global ENEMY_H_SPRITE_PTR
.global ENEMY_V_SPRITE_PTR
.global EXPLOSION_1_SPRITE_PTR
.global EXPLOSION_2_SPRITE_PTR
.global EXPLOSION_3_SPRITE_PTR
.global SKULL_1_SPRITE_PTR
.global SKULL_2_SPRITE_PTR
.global SKULL_3_SPRITE_PTR
.global D_1_SPRITE_PTR
.global D_2_SPRITE_PTR
.global D_3_SPRITE_PTR
.global A_1_SPRITE_PTR
.global A_2_SPRITE_PTR
.global A_3_SPRITE_PTR
.global M_1_SPRITE_PTR
.global M_2_SPRITE_PTR
.global M_3_SPRITE_PTR
.global O_1_SPRITE_PTR
.global O_2_SPRITE_PTR
.global O_3_SPRITE_PTR
.global N_1_SPRITE_PTR
.global N_2_SPRITE_PTR
.global N_3_SPRITE_PTR

.enum SPRITE_SIZE
    W_08 = %00000000
    W_16 = %00010000
    W_32 = %00100000
    W_64 = %00110000
    H_08 = %00000000
    H_16 = %01000000
    H_32 = %10000000
    H_64 = %11000000
.endenum
