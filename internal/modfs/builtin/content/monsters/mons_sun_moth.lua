-- sun moth (MONS_SUN_MOTH) is a DCSS monster profile with 9 hit dice and
-- speed 12.
-- Its first melee contact is AT_BITE for 30 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SUN_MOTH when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SUN_MOTH",
    status = "defined",
    name = "sun moth",
    glyph = 121,
    colour_id = "ETC_GOLD",
    flags = {
        "M_NO_SKELETON",
        "M_FLIES",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_MOTH",
    species_id = "MONS_SUN_MOTH",
    holiness = {
        "MH_HOLY",
    },
    willpower = 60,
    -- sun moth offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_STICKY_FLAME",
            damage = 30,
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
    hd = 9,
    average_hp_10x = 805,
    ac = 6,
    ev = 12,
    spellbook_id = spellbooks.MST_SUN_MOTH,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For sun moth, energy costs combine with speed 12 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_INSECT_WINGED",
    tile = {
        id = "TILEP_MONS_SUN_MOTH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SUN_MOTH",
}

register.definition(categories.MONSTERS, definition)

return definition
