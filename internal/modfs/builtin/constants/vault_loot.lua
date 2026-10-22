-- Source dungeon.lua defines these fixed weighted lists for useful vault
-- consumables. Keeping them together lets map hooks import one name rather
-- than repeat ten item expressions and drift when the catalog changes.
local loot = {
    -- The source's ordinary auxiliary-armour pool has equal alternatives.
    -- Keep it shared so DES hooks cannot drift on one equipment subtype.
    AUX_ARMOUR =
        "cloak / scarf / helmet / hat / pair of gloves / pair of boots",

    GOOD_SCROLLS =
        "w:120 scroll of identify no_pickup / " ..
        "w:55 scroll of identify no_pickup q:2 / " ..
        "w:15 scroll of identify no_pickup q:3 / " ..
        "w:85 scroll of teleportation no_pickup / " ..
        "w:45 scroll of teleportation no_pickup q:2 / " ..
        "w:10 scroll of teleportation no_pickup q:3 / " ..
        "w:85 any concealment scroll no_pickup / " ..
        "w:33 any concealment scroll no_pickup q:2 / " ..
        "w:95 scroll of enchant weapon no_pickup / " ..
        "w:40 scroll of enchant weapon no_pickup q:2 / " ..
        "w:54 scroll of blinking no_pickup / " ..
        "w:22 scroll of blinking no_pickup q:2 / " ..
        "w:54 scroll of enchant armour no_pickup / " ..
        "w:22 scroll of enchant armour no_pickup q:2 / " ..
        "w:45 scroll of magic mapping no_pickup / " ..
        "w:20 scroll of magic mapping no_pickup q:2 / " ..
        "w:40 scroll of amnesia no_pickup / " ..
        "w:15 scroll of amnesia no_pickup q:2 / " ..
        "w:33 scroll of immolation no_pickup q:1 / " ..
        "w:11 scroll of immolation no_pickup q:2 / " ..
        "w:30 scroll of silence no_pickup q:1 / " ..
        "w:10 scroll of silence no_pickup q:2 / " ..
        "w:11 scroll of acquirement no_pickup q:1 / " ..
        "w:4 scroll of acquirement no_pickup q:2 / " ..
        "w:1 scroll of acquirement no_pickup q:3 / " ..
        "w:15 scroll of brand weapon no_pickup q:1 / " ..
        "w:15 scroll of torment no_pickup q:1 / " ..
        "w:15 scroll of vulnerability no_pickup",

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
