-- Mnoleg (MONS_MNOLEG) is a DCSS monster profile with 17 hit dice and speed
-- 13.
-- Its first melee contact is AT_CLAW for 40 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_MNOLEG when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_MNOLEG",
    status = "defined",
    name = "Mnoleg",
    glyph = 38,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_TALL_TILE",
        "M_GENDER_NEUTRAL",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_PANDEMONIUM_LORD",
    species_id = "MONS_MNOLEG",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Mnoleg offers AT_CLAW as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_TENTACLE_SLAP",
            flavour_id = "AF_MUTATE",
            damage = 35,
        },
        {
            type_id = "AT_GORE",
            flavour_id = "AF_PLAIN",
            damage = 30,
        },
        {
            type_id = "AT_KICK",
            flavour_id = "AF_BLINK",
            damage = 23,
        },
    },
    hd = 17,
    average_hp_10x = 3485,
    ac = 10,
    ev = 25,
    spellbook_id = spellbooks.MST_MNOLEG,
    shout_id = "S_BUZZ",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For Mnoleg, energy costs combine with speed 13 to determine action cadence,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_MNOLEG",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
