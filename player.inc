.global spawn_player
.global kill_player
.global handle_steering
.global update_player

.global player_data

.enum PLAYER_STATE
    ALIVE       = 0
    DYING       = 1
    DEAD        = 2
    RESPAWNING  = 3
.endenum
