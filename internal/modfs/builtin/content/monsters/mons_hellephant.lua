-- hellephant (MONS_HELLEPHANT) is a DCSS monster profile with 20 hit dice and
-- speed 10.
-- Its first melee contact is AT_TRAMPLE for 45 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_HELLEPHANT when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_HELLEPHANT",
    status = "defined",
    name = "hellephant",
    glyph = 89,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 10,
    genus_id = "MONS_ELEPHANT",
    species_id = "MONS_HELLEPHANT",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 140,
    -- hellephant offers AT_TRAMPLE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 45,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_GORE",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 20,
    average_hp_10x = 1700,
    ac = 13,
    ev = 10,
    spellbook_id = spellbooks.MST_HELLEPHANT,
    leaves_corpse = true,
    shout_id = "S_TRUMPET",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For hellephant, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_HELLEPHANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_HELLEPHANT",
}

register.definition(categories.MONSTERS, definition)

return definition
