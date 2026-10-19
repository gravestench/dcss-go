-- ugly thing (MONS_UGLY_THING) is a DCSS monster profile with 12 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 17 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_UGLY_THING",
    status = "defined",
    name = "ugly thing",
    glyph = 117,
    colour_id = "COLOUR_UNDEF",
    flags = {
        "M_WARM_BLOOD",
        "M_HERD",
        "M_NO_GEN_DERIVED",
        "M_GHOST_DEMON",
    },
    xp_modifier = 6,
    genus_id = "MONS_UGLY_THING",
    species_id = "MONS_UGLY_THING",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- ugly thing offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 17,
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
    hd = 12,
    average_hp_10x = 660,
    ac = 4,
    ev = 10,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_GURGLE",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For ugly thing, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_PROGRAM_BUG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_UGLY_THING",
    -- Spawn rows place ugly thing in depth bands beginning at 11 through 18; they
    -- do not mutate existing actors.
    population = {
        {
            source_order = 60,
            min_depth = 11,
            max_depth = 18,
            rarity = 800,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
