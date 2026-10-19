-- putrid mouth (MONS_PUTRID_MOUTH) is a DCSS monster profile with 14 hit dice
-- and speed 10.
-- Its first melee contact is AT_BITE for 30 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_PUTRID_MOUTH when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_PUTRID_MOUTH",
    status = "defined",
    name = "putrid mouth",
    glyph = 87,
    colour_id = "GREEN",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    xp_modifier = 15,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_PUTRID_MOUTH",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 100,
    -- putrid mouth offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_POISON_STRONG",
            damage = 30,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_DRAIN_STAT",
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
    },
    hd = 14,
    average_hp_10x = 700,
    ac = 5,
    ev = 14,
    spellbook_id = "MST_PUTRID_MOUTH",
    shout_id = "S_MOAN",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For putrid mouth, energy costs combine with speed 10 to determine action
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
        id = "TILEP_MONS_PUTRID_MOUTH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
