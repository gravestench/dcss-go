-- sky beast (MONS_SKY_BEAST) is a DCSS monster profile with 5 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 5 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SKY_BEAST",
    status = "defined",
    name = "sky beast",
    glyph = 89,
    colour_id = "LIGHTCYAN",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_SKY_BEAST",
    species_id = "MONS_SKY_BEAST",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- sky beast offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ELEC",
            damage = 5,
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
    ac = 3,
    ev = 13,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For sky beast, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SKY_BEAST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SKY_BEAST",
    -- Spawn rows place sky beast in depth bands beginning at 6 through 8; they do
    -- not mutate existing actors.
    population = {
        {
            source_order = 39,
            min_depth = 6,
            max_depth = 8,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
