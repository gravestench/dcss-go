-- Source dungeon.lua defines these fixed weighted lists for useful vault
-- consumables. Keeping them together lets map hooks import one name rather
-- than repeat ten item expressions and drift when the catalog changes.
local loot = {
    SCROLLS =
        "w:15 scroll of teleportation / " ..
        "w:15 any concealment scroll / " ..
        "w:15 scroll of fear / " ..
        "w:10 scroll of blinking / " ..
        "w:10 scroll of summoning / " ..
        "w:8 scroll of magic mapping / " ..
        "w:10 scroll of enchant weapon / " ..
        "w:10 scroll of enchant armour / " ..
        "w:5 scroll of brand weapon / " ..
        "w:2 scroll of acquirement",
    POTIONS =
        "w:16 potion of haste / " ..
        "w:16 potion of heal wounds / " ..
        "w:11 potion of might / " ..
        "w:11 potion of invisibility / " ..
        "w:11 potion of magic / " ..
        "w:11 potion of mutation / " ..
        "w:8 potion of cancellation / " ..
        "w:7 potion of brilliance / " ..
        "w:7 potion of resistance / " ..
        "w:2 potion of experience",
}

return loot
