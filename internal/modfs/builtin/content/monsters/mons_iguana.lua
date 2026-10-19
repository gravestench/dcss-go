-- iguana (MONS_IGUANA) is a DCSS monster profile with 3 hit dice and speed
-- 10.
-- Its first melee contact is AT_BITE for 15 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_IGUANA",
    status = "defined",
    name = "iguana",
    glyph = 108,
    colour_id = "BLUE",
    flags = {
        "M_COLD_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_GIANT_LIZARD",
    species_id = "MONS_IGUANA",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- iguana offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
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
    hd = 3,
    average_hp_10x = 165,
    ac = 5,
    ev = 9,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_HISS",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For iguana, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_IGUANA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_IGUANA",
    -- Spawn rows place iguana in depth bands beginning at 4 through 7; they do not
    -- mutate existing actors.
    population = {
        {
            source_order = 24,
            min_depth = 4,
            max_depth = 7,
            rarity = 1000,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
