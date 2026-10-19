-- shadow wraith (MONS_SHADOW_WRAITH) is a DCSS monster profile with 10 hit
-- dice and speed 10.
-- Its first melee contact is AT_HIT for 27 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")

local definition = {
    id = "MONS_SHADOW_WRAITH",
    status = "defined",
    name = "shadow wraith",
    glyph = 87,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    xp_modifier = 15,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_SHADOW_WRAITH",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 100,
    -- shadow wraith offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_DRAIN_SPEED",
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
    hd = 10,
    average_hp_10x = 550,
    ac = 7,
    ev = 7,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For shadow wraith, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_SHADOW_WRAITH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
    -- Spawn rows place shadow wraith in depth bands beginning at 16 through 24;
    -- they do not mutate existing actors.
    population = {
        {
            source_order = 89,
            min_depth = 16,
            max_depth = 24,
            rarity = 25,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
