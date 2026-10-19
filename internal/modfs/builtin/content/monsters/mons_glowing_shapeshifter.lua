-- glowing shapeshifter (MONS_GLOWING_SHAPESHIFTER) is a DCSS monster profile
-- with 10 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 15 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_GLOWING_SHAPESHIFTER",
    status = "defined",
    name = "glowing shapeshifter",
    glyph = 112,
    colour_id = "LIGHTRED",
    xp_modifier = 10,
    genus_id = "MONS_SHAPESHIFTER",
    species_id = "MONS_GLOWING_SHAPESHIFTER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- glowing shapeshifter offers AT_HIT as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 15,
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
    hd = 10,
    average_hp_10x = 550,
    ev = 10,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For glowing shapeshifter, energy costs combine with speed 10 to determine
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_GLOWING_SHAPESHIFTER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GLOWING_SHAPESHIFTER",
    -- Spawn rows place glowing shapeshifter in depth bands beginning at 23 through
    -- 27; they do not mutate existing actors.
    population = {
        {
            min_depth = 23,
            max_depth = 27,
            rarity = 136,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
