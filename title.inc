.global init_title_screen
.global update_title_screen

.global title_state

.enum TITLE_STATE
    SLIDING_D = 0
    SLIDING_A = 1
    SLIDING_M = 2
    SLIDING_O = 3
    SLIDING_N = 4
    ANIMATING = 5
    DONE      = 6
.endenum
