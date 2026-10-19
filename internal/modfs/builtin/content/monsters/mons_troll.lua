-- troll (MONS_TROLL) is a DCSS monster profile with 7 hit dice and speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_TROLL",
    status = "defined",
    name = "troll",
    glyph = 84,
    colour_id = "BROWN",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_FAST_REGEN",
    },
    xp_modifier = 10,
    genus_id = "MONS_TROLL",
    species_id = "MONS_TROLL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- troll offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 7,
    average_hp_10x = 385,
    ac = 3,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For troll, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_TROLL",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_TROLL",
    -- Spawn rows place troll in depth bands beginning at 9 through 14; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 54,
            min_depth = 9,
            max_depth = 14,
            rarity = 800,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
