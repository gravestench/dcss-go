-- vampire mosquito (MONS_VAMPIRE_MOSQUITO) is a DCSS monster profile with 5
-- hit dice and speed 19.
-- Its first melee contact is AT_BITE for 13 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_VAMPIRE_MOSQUITO",
    status = "defined",
    name = "vampire mosquito",
    glyph = 121,
    colour_id = "LIGHTGREY",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
    },
    xp_modifier = 10,
    genus_id = "MONS_VAMPIRE_MOSQUITO",
    species_id = "MONS_VAMPIRE_MOSQUITO",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 20,
    -- vampire mosquito offers AT_BITE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_VAMPIRIC",
            damage = 13,
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
    ev = 15,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    leaves_corpse = true,
    shout_id = "S_BUZZ",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 19,
    -- For vampire mosquito, energy costs combine with speed 19 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_VAMPIRE_MOSQUITO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_VAMPIRE_MOSQUITO",
    -- Spawn rows place vampire mosquito in depth bands beginning at 10 through 15;
    -- they do not mutate existing actors.
    population = {
        {
            min_depth = 10,
            max_depth = 15,
            rarity = 500,
            curve = curves.PEAK,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
