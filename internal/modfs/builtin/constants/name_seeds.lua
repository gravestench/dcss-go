-- The pinned C++ source packs scroll appearance seeds into three bytes:
-- two independently drawn values from 0 to 150, then OBJ_SCROLLS = 5
-- under its tag-34 object class layout.
local seeds = {
    SCROLL_SIDE = 151,
    SECOND_BYTE = 256,
    CLASS_BYTE = 65536,
    SCROLL_CLASS = 5,
}

return seeds
