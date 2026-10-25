-- These are the three source make_name modes, not content IDs. Callers
-- choose one by purpose so a scroll never relies on a private magic number.
local modes = {
    ORDINARY = "ordinary",
    SCROLL = "scroll",
    JIYVA = "jiyva",
}

return modes
