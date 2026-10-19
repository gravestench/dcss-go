-- halazid warlock (MONS_HALAZID_WARLOCK) is a DCSS monster profile with 18
-- hit dice and speed 10.
-- Its first melee contact is AT_TOUCH for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_HALAZID_WARLOCK when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_HALAZID_WARLOCK",
    status = "defined",
    name = "halazid warlock",
    glyph = 76,
    colour_id = "GREEN",
    flags = {
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 2,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_LICH",
    species_id = "MONS_LICH",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 100,
    -- halazid warlock offers AT_TOUCH as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TOUCH",
            flavour_id = "AF_PAIN",
            damage = 20,
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
    hd = 18,
    average_hp_10x = 750,
    ac = 8,
    ev = 12,
    spellbook_id = "MST_HALAZID_WARLOCK",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For halazid warlock, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_HALAZID_WARLOCK",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
