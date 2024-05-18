.global reset_input
.global read_input
.global clear_steering_input

.global current_input

.enum INPUT
    NONE = 0
    RIGHT = (1 << 0)
    LEFT = (1 << 1)
    DOWN = (1 << 2)
    UP = (1 << 3)
    FIRE = (1 << 4)
.endenum
