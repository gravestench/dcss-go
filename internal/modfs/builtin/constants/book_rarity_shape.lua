-- Flat and rising rarity curves decide how fixed books are weighted by branch depth.

-- Source: crawl-ref/source/spl-book.cc fixed-book rarity curves.
local shape = {
    FLAT = "flat",
    RISE = "rise",
}

return shape
