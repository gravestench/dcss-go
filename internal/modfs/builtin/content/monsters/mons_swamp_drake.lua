-- swamp drake (MONS_SWAMP_DRAKE) is a DCSS monster profile with 4 hit dice
-- and speed 10.
-- Its first melee contact is AT_BITE for 14 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SWAMP_DRAKE when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SWAMP_DRAKE",
    status = "defined",
    name = "swamp drake",
    glyph = 107,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 20,
    genus_id = "MONS_DRAKE",
    species_id = "MONS_SWAMP_DRAKE",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- swamp drake offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 14,
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 4,
    average_hp_10x = 300,
    ac = 3,
    ev = 11,
    spellbook_id = "MST_SWAMP_DRAKE",
    leaves_corpse = true,
    shout_id = "S_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For swamp drake, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SWAMP_DRAKE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SWAMP_DRAKE",
}

register.definition(categories.MONSTERS, definition)

return definition
