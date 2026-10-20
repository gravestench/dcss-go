-- howler monkey (MONS_HOWLER_MONKEY) is a DCSS monster profile with 3 hit
-- dice and speed 12.
-- Its first melee contact is AT_HIT for 8 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SCREAMER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_HOWLER_MONKEY",
    status = "defined",
    name = "howler monkey",
    glyph = 104,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 15,
    genus_id = "MONS_HOWLER_MONKEY",
    species_id = "MONS_HOWLER_MONKEY",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 10,
    -- howler monkey offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
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
    hd = 3,
    average_hp_10x = 185,
    ac = 1,
    ev = 11,
    spellbook_id = spellbooks.MST_SCREAMER,
    leaves_corpse = true,
    shout_id = "S_HOWL",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For howler monkey, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID_TAILED",
    tile = {
        id = "TILEP_MONS_HOWLER_MONKEY",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HOWLER_MONKEY",
}

register.definition(categories.MONSTERS, definition)

return definition
