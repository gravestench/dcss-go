-- the Lernaean hydra (MONS_LERNAEAN_HYDRA) is a DCSS monster profile with 30
-- hit dice and speed 10.
-- Its first melee contact is AT_BITE for 18 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_LERNAEAN_HYDRA",
    status = "defined",
    name = "the Lernaean hydra",
    glyph = 68,
    colour_id = "YELLOW",
    flags = {
        "M_UNIQUE",
        "M_COLD_BLOOD",
        "M_FAST_REGEN",
        "M_TALL_TILE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 11,
    genus_id = "MONS_HYDRA",
    species_id = "MONS_HYDRA",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- the Lernaean hydra offers AT_BITE as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 18,
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
    hd = 30,
    average_hp_10x = 1500,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 10,
    -- For the Lernaean hydra, energy costs combine with speed 10 to determine
    -- action cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
