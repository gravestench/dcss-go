-- jorogumo (MONS_JOROGUMO) is a DCSS monster profile with 12 hit dice and
-- speed 12.
-- Its first melee contact is AT_HIT for 28 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_JOROGUMO when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_JOROGUMO",
    status = "defined",
    name = "jorogumo",
    glyph = 72,
    colour_id = "BLUE",
    flags = {
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_SEE_INVIS",
        "M_WEB_IMMUNE",
    },
    xp_modifier = 10,
    genus_id = "MONS_JOROGUMO",
    species_id = "MONS_JOROGUMO",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- jorogumo offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_POISON_PARALYSE",
            damage = 28,
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
    average_hp_10x = 850,
    ac = 4,
    ev = 14,
    spellbook_id = spellbooks.MST_JOROGUMO,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For jorogumo, energy costs combine with speed 12 to determine action
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
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_JOROGUMO",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_JOROGUMO",
}

register.definition(categories.MONSTERS, definition)

return definition
