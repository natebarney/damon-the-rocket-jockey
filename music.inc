.global music_init
.global music_update
.global music_rewind
.global music_play
.global music_resume
.global music_stop
.global music_cycle_type

.global music_load_title
.global music_load_level
.global music_load_next_round
.global music_load_level_complete

.global music_state

.enum MUSIC_STATE
    STOPPED     = 0
    PLAYING     = 1
    RESUMING    = 2
.endenum

.enum MUSIC_TYPE
    PCM     = 0
    FM      = 1
    FM_MIN  = 2
    MAX     = 3
.endenum
