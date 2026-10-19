-- ironbound frostheart (MONS_IRONBOUND_FROSTHEART) is a DCSS monster profile
-- with 12 hit dice and speed 10.
-- Its first melee contact is AT_TOUCH for 25 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_IRONBOUND_FROSTHEART when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_IRONBOUND_FROSTHEART",
    status = "defined",
    name = "ironbound frostheart",
    glyph = 112,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_HUMAN",
    species_id = "MONS_HUMAN",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- ironbound frostheart offers AT_TOUCH as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_TOUCH",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 12,
    average_hp_10x = 600,
    ev = 10,
    spellbook_id = "MST_IRONBOUND_FROSTHEART",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For ironbound frostheart, energy costs combine with speed 10 to determine
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
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_IRONBOUND_FROSTHEART",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
