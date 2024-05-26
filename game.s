.include "bullet.inc"
.include "color.inc"
.include "enemy.inc"
.include "game.inc"
.include "graphics.inc"
.include "input.inc"
.include "kernal.inc"
.include "level.inc"
.include "mobile.inc"
.include "music.inc"
.include "pellet.inc"
.include "player.inc"
.include "score.inc"
.include "sound.inc"
.include "sprite.inc"
.include "title.inc"
.include "vera.inc"

GET_READY_FRAMES = 120
GAME_OVER_FRAMES = 180

.data

game_frame_counter: .res 1
game_state: .res 1

.code

.proc game_init

    jsr init_score
    jsr sound_init
    jsr music_init

    lda #GAME_STATE::TITLE
    ; intentional fall-through to game_set_state

.endproc

.proc game_set_state

    sta game_state

    cmp #GAME_STATE::TITLE
    bne not_title
    jmp init_title
not_title:

    cmp #GAME_STATE::GET_READY
    bne not_get_ready
    jmp init_get_ready
not_get_ready:

    cmp #GAME_STATE::NEW_LEVEL
    bne not_new_level
    jmp init_new_level
not_new_level:

    cmp #GAME_STATE::STARTING
    bne not_starting
    jmp init_starting
not_starting:

    cmp #GAME_STATE::PLAYING
    bne not_playing
    jmp init_playing
not_playing:

    cmp #GAME_STATE::DYING
    bne not_dying
    jmp init_dying
not_dying:

    cmp #GAME_STATE::LEVEL_COMPLETE
    bne not_complete
    jmp init_level_complete
not_complete:

    cmp #GAME_STATE::GAME_OVER
    bne not_game_over
    jmp init_game_over
not_game_over:

    rts

.endproc

.proc game_update

    jsr GETIN
    cmp #'Q'
    bne not_quitting
    stz $01     ; restore default rom bank
    jmp ($fffa) ; jump to NMI handler (like ctrl-alt-restore)
not_quitting:
    cmp #'M'
    bne not_muting
    jsr music_toggle_mute
not_muting:

    jsr update_bullet_sound
    jsr update_crash_sound
    jsr update_bonus_sound
    jsr music_update

    lda game_state

    cmp #GAME_STATE::TITLE
    bne not_title
    jmp update_title
not_title:

    lda game_state

    cmp #GAME_STATE::GET_READY
    bne not_get_ready
    jmp update_get_ready
not_get_ready:

    cmp #GAME_STATE::NEW_LEVEL
    bne not_new_level
    jmp update_new_level
not_new_level:

    cmp #GAME_STATE::STARTING
    bne not_starting
    jmp update_starting
not_starting:

    cmp #GAME_STATE::PLAYING
    bne not_playing
    jmp update_playing
not_playing:

    cmp #GAME_STATE::DYING
    bne not_dying
    jmp update_dying
not_dying:

    cmp #GAME_STATE::LEVEL_COMPLETE
    bne not_complete
    jmp update_level_complete
not_complete:

    cmp #GAME_STATE::GAME_OVER
    bne not_game_over
    jmp update_game_over
not_game_over:

    rts

.endproc

.proc init_title

    jmp init_title_screen

.endproc

.proc update_title

    jsr update_title_screen
    lda title_state
    cmp #TITLE_STATE::DONE
    bne title_not_done
    lda #GAME_STATE::GET_READY
    jmp game_set_state
title_not_done:
    rts

.endproc

.proc init_get_ready

    lda #GET_READY_FRAMES
    sta game_frame_counter
    jsr music_stop
    jsr reset_sprites
    jmp draw_get_ready_screen

.endproc

.proc update_get_ready

    dec game_frame_counter
    bne not_done
    lda #GAME_STATE::NEW_LEVEL
    jmp game_set_state
not_done:
    rts

.endproc

.proc init_new_level

    jsr init_pellet_map
    jsr draw_level_screen
    jsr spawn_player
    jmp init_enemies

.endproc

.proc update_new_level

    lda #GAME_STATE::STARTING
    jmp game_set_state

.endproc

.proc init_starting

    jsr music_load_next_round
    jsr music_play
    jsr reset_input
    jsr init_bullets
    jsr spawn_player
    jmp reset_enemies

.endproc

.proc update_starting

    lda music_state
    cmp #MUSIC_STATE::STOPPED
    bne not_done
    lda #GAME_STATE::PLAYING
    jmp game_set_state
not_done:
    rts

.endproc

.proc init_playing

    jsr music_load_level
    jsr music_play
    jmp reset_input

.endproc

.proc update_playing

    jsr get_pellet_indices
    beq no_pellet
    jsr does_pellet_exist
    beq no_pellet
    jsr mark_pellet_gone
    jsr blank_pellet
    jsr add_score
no_pellet:

    jsr read_input
    jsr handle_steering
    jsr update_player
    lda player_data + MOBILE::state
    cmp #PLAYER_STATE::DYING
    bne not_killed
    lda #GAME_STATE::DYING
    jmp game_set_state
not_killed:

    lda active_enemies
    bne not_done
    lda #GAME_STATE::LEVEL_COMPLETE
    jmp game_set_state
not_done:

    jsr handle_player_fire
    jsr update_bullets
    jmp update_enemies

.endproc

.proc init_dying

    jsr freeze_bullets
    jsr music_stop
    jsr play_crash_sound
    jmp kill_player

.endproc

.proc update_dying

    jsr update_enemies
    lda player_data + MOBILE::state
    cmp #PLAYER_STATE::RESPAWNING
    bne not_done
    jsr dec_ships
    lda ships
    beq game_over
    lda #GAME_STATE::STARTING
    jmp game_set_state
game_over:
    lda #GAME_STATE::GAME_OVER
    jmp game_set_state
not_done:
    jmp update_player

.endproc

.proc init_level_complete

    jsr freeze_bullets
    jsr music_stop
    jsr music_load_level_complete
    jmp music_play

.endproc

.proc update_level_complete

    lda music_state
    cmp #MUSIC_STATE::STOPPED
    bne not_done
    jsr inc_level_number
    lda #GAME_STATE::GET_READY
    jmp game_set_state
not_done:
    rts

.endproc

.proc init_game_over

    lda #GAME_OVER_FRAMES
    sta game_frame_counter
    jsr music_stop
    jsr update_hiscore
    jsr reset_sprites
    jmp draw_game_over

.endproc

.proc update_game_over

    dec game_frame_counter
    bne not_done
    lda #GAME_STATE::TITLE
    jmp game_set_state
not_done:
    rts

.endproc

.proc draw_get_ready_screen

    jsr clear_l1_tilemap

    lda #BOARD_XMIN + 16
    sta xcoord
    lda #BOARD_YMIN + 10
    sta ycoord
    lda #COLOR::WHITE
    sta color
    lda #<get_ready_str
    sta copy_ram_ptr
    lda #>get_ready_str
    sta copy_ram_ptr+1
    jmp draw_string

.endproc

.proc draw_game_over

    lda #BOARD_XMIN + 12
    sta xcoord
    lda #BOARD_YMIN + 10
    sta ycoord
    lda #COLOR::YELLOW
    sta color
    lda #<game_over_str
    sta copy_ram_ptr
    lda #>game_over_str
    sta copy_ram_ptr+1
    jmp draw_string

.endproc

.rodata

get_ready_str: .asciiz "GET READY"
game_over_str: .asciiz "GAME OVER"
