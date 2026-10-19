-- unseen horror (MONS_UNSEEN_HORROR) is a DCSS monster profile with 7 hit
-- dice and speed 30.
-- Its first melee contact is AT_HIT for 12 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_UNSEEN_HORROR",
    status = "defined",
    name = "unseen horror",
    glyph = 120,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_INVIS",
        "M_BATTY",
    },
    xp_modifier = 6,
    genus_id = "MONS_UNSEEN_HORROR",
    species_id = "MONS_UNSEEN_HORROR",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- unseen horror offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 12,
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
    hd = 7,
    average_hp_10x = 385,
    ac = 5,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 30,
    -- For unseen horror, energy costs combine with speed 30 to determine action
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
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_UNSEEN_HORROR",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place unseen horror in depth bands beginning at 10 through 13;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 56,
            min_depth = 10,
            max_depth = 13,
            rarity = 350,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
