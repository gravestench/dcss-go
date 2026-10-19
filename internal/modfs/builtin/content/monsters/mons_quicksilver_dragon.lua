-- quicksilver dragon (MONS_QUICKSILVER_DRAGON) is a DCSS monster profile with
-- 16 hit dice and speed 15.
-- Its first melee contact is AT_BITE for 25 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_QUICKSILVER_DRAGON when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_QUICKSILVER_DRAGON",
    status = "defined",
    name = "quicksilver dragon",
    glyph = 68,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 14,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_QUICKSILVER_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 140,
    -- quicksilver dragon offers AT_BITE as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 16,
    average_hp_10x = 880,
    ac = 10,
    ev = 15,
    spellbook_id = "MST_QUICKSILVER_DRAGON",
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For quicksilver dragon, energy costs combine with speed 15 to determine
    -- action cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_QUICKSILVER_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_QUICKSILVER_DRAGON",
}

register.definition(categories.MONSTERS, definition)

return definition
