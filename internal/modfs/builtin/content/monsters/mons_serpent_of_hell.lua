-- the Serpent of Hell (MONS_SERPENT_OF_HELL) is a DCSS monster profile with
-- 17 hit dice and speed 14.
-- Its first melee contact is AT_BITE for 35 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SERPENT_OF_HELL_GEH when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SERPENT_OF_HELL",
    status = "defined",
    name = "the Serpent of Hell",
    glyph = 68,
    colour_id = "ETC_FIRE",
    flags = {
        "M_SEE_INVIS",
        "M_UNIQUE",
        "M_CRASH_DOORS",
        "M_FLIES",
        "M_TALL_TILE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_DAMNATION",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
    },
    xp_modifier = 21,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_SERPENT_OF_HELL",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 180,
    -- the Serpent of Hell offers AT_BITE as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_FIRE",
            damage = 35,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 17,
    average_hp_10x = 2805,
    ac = 16,
    ev = 12,
    spellbook_id = spellbooks.MST_SERPENT_OF_HELL_GEH,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 14,
    -- For the Serpent of Hell, energy costs combine with speed 14 to determine
    -- action cadence, not an unconditional action each turn.
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
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SERPENT_OF_HELL_GEHENNA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
