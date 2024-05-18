.global game_init
.global game_update
.global game_set_state

.enum GAME_STATE
    TITLE           = 0
    GET_READY       = 1
    NEW_LEVEL       = 2
    STARTING        = 3
    PLAYING         = 4
    DYING           = 5
    LEVEL_COMPLETE  = 6
    GAME_OVER       = 7
.endenum
