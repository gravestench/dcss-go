-- Ice Fiend (MONS_ICE_FIEND) is a DCSS monster profile with 18 hit dice and
-- speed 10.
-- Its first melee contact is AT_CLAW for 25 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_ICE_FIEND when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_ICE_FIEND",
    status = "defined",
    name = "Ice Fiend",
    glyph = 49,
    colour_id = "WHITE",
    flags = {
        "M_SEE_INVIS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = -1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 17,
    genus_id = "MONS_ICE_FIEND",
    species_id = "MONS_ICE_FIEND",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Ice Fiend offers AT_CLAW as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_COLD",
            damage = 25,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_COLD",
            damage = 25,
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
    ac = 15,
    ev = 6,
    spellbook_id = spellbooks.MST_ICE_FIEND,
    shout_id = "S_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Ice Fiend, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_ICE_FIEND",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
