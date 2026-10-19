-- very ugly thing (MONS_VERY_UGLY_THING) is a DCSS monster profile with 18
-- hit dice and speed 10.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_VERY_UGLY_THING",
    status = "defined",
    name = "very ugly thing",
    glyph = 117,
    colour_id = "COLOUR_UNDEF",
    flags = {
        "M_WARM_BLOOD",
        "M_HERD",
        "M_NO_GEN_DERIVED",
        "M_GHOST_DEMON",
    },
    xp_modifier = 10,
    genus_id = "MONS_UGLY_THING",
    species_id = "MONS_VERY_UGLY_THING",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- very ugly thing offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 27,
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
    hd = 18,
    average_hp_10x = 990,
    ac = 6,
    ev = 10,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_GURGLE",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For very ugly thing, energy costs combine with speed 10 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 9,
        swim = 9,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_VERY_UGLY_THING",
    -- Spawn rows place very ugly thing in depth bands beginning at 17 through 23;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 91,
            min_depth = 17,
            max_depth = 23,
            rarity = 89,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
