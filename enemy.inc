.global select_first_enemy
.global select_next_enemy
.global load_enemy_rect
.global init_enemies
.global reset_enemies
.global kill_enemy
.global update_enemies

.global active_enemies

MAX_ENEMIES = 5

.enum ENEMY_STATE
    RESPAWNING  = 0
    DECIDING    = 1
    UTURNING    = 2
    MOVING      = 3
    EXPLODING   = 4
    DEAD        = 5
    RETIRED     = 6
.endenum
