-- necrophage (MONS_NECROPHAGE) is a DCSS monster profile with 5 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 8 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_NECROPHAGE",
    status = "defined",
    name = "necrophage",
    glyph = 110,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_ZOMBIE",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 8,
    genus_id = "MONS_GHOUL",
    species_id = "MONS_NECROPHAGE",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    -- necrophage offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN",
            damage = 8,
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
    hd = 5,
    average_hp_10x = 275,
    ac = 2,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For necrophage, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_NECROPHAGE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_NECROPHAGE",
    -- Spawn rows place necrophage in depth bands beginning at 4 through 8; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 27,
            min_depth = 4,
            max_depth = 8,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
