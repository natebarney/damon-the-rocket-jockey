.global letter_tile_data
.global letter_tile_data_end
.global number_tile_data
.global number_tile_data_end
.global graphic_tile_data
.global graphic_tile_data_end

.global tile_period
.global tile_period_end
.global tile_backtick
.global tile_backtick_end
.global tile_apostrophe
.global tile_apostrophe_end

.enum TILE

    NUMBER_START = $30
    GRAPHIC_START = $80

    PERIOD = $2E
    BACKTICK = $40
    APOSTROPHE = $27

    BORDER_TOP_LEFT = $80
    BORDER_TOP_RIGHT = $81
    BORDER_BOTTOM_LEFT = $82
    BORDER_BOTTOM_RIGHT = $83
    BORDER_VERTICAL = $84
    BORDER_HORIZONTAL = $85
    BORDER_TEE_DOWN = $86
    BORDER_TEE_UP = $87

    PELLET_TOP_LEFT = $88
    PELLET_TOP_RIGHT = $89
    PELLET_BOTTOM_LEFT = $8A
    PELLET_BOTTOM_RIGHT = $8B

    BARRIER = $8C

    LEVEL1_TOP_LEFT = $8D
    LEVEL1_TOP_RIGHT = $8E
    LEVEL1_BOTTOM_LEFT = $8F
    LEVEL1_BOTTOM_RIGHT = $90

    LEVEL2 = $91
    LEVEL3 = $92
    LEVEL4 = $93

    LEVEL5_TOP_LEFT = $94
    LEVEL5_TOP_RIGHT = $95
    LEVEL5_BOTTOM_LEFT = $96
    LEVEL5_BOTTOM_RIGHT = $97

.endenum