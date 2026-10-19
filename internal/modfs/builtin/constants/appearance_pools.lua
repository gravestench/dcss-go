-- Unidentified item classes draw from separate appearance pools so a wand look cannot become a ring look.

local pools = {
    WAND = "wand",
    POTION = "potion",
    SCROLL = "scroll",
    RING = "ring",
    AMULET = "amulet",
    STAFF = "staff",
}

return pools
