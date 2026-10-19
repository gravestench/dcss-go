-- Geryon (MONS_GERYON) is a DCSS monster profile with 15 hit dice and speed
-- 10.
-- Its first melee contact is AT_TAIL_SLAP for 35 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_GERYON when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GERYON",
    status = "defined",
    name = "Geryon",
    glyph = 38,
    colour_id = "GREEN",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_MALE",
        "M_FLIES",
        "M_TALL_TILE",
    },
    xp_modifier = 15,
    genus_id = "MONS_HELL_LORD",
    species_id = "MONS_GERYON",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 120,
    -- Geryon offers AT_TAIL_SLAP as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_TAIL_SLAP",
            flavour_id = "AF_REACH",
            damage = 35,
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
    hd = 15,
    average_hp_10x = 3000,
    ac = 15,
    ev = 6,
    spellbook_id = "MST_GERYON",
    shout_id = "S_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Geryon, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_GERYON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
