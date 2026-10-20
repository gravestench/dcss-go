-- deep troll earth mage (MONS_DEEP_TROLL_EARTH_MAGE) is a DCSS monster
-- profile with 12 hit dice and speed 10.
-- Its first melee contact is AT_BITE for 27 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_DEEP_TROLL_EARTH_MAGE when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_DEEP_TROLL_EARTH_MAGE",
    status = "defined",
    name = "deep troll earth mage",
    glyph = 84,
    colour_id = "MAGENTA",
    flags = {
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_UNBLINDABLE",
        "M_SPEAKS",
    },
    xp_modifier = 10,
    genus_id = "MONS_TROLL",
    species_id = "MONS_DEEP_TROLL",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- deep troll earth mage offers AT_BITE as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 27,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 12,
    average_hp_10x = 480,
    ac = 12,
    ev = 10,
    spellbook_id = spellbooks.MST_DEEP_TROLL_EARTH_MAGE,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For deep troll earth mage, energy costs combine with speed 10 to determine
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_DEEP_TROLL_EARTH_MAGE",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
