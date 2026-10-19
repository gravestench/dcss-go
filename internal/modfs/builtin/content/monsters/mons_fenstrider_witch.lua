-- fenstrider witch (MONS_FENSTRIDER_WITCH) is a DCSS monster profile with 16
-- hit dice and speed 13.
-- Its first melee contact is AT_HIT for 25 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_FENSTRIDER_WITCH when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_FENSTRIDER_WITCH",
    status = "defined",
    name = "fenstrider witch",
    glyph = 72,
    colour_id = "LIGHTMAGENTA",
    flags = {
        "M_SPEAKS",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_NEG",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_FENSTRIDER_WITCH",
    species_id = "MONS_FENSTRIDER_WITCH",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- fenstrider witch offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 25,
        },
        {
            type_id = "AT_KICK",
            flavour_id = "AF_PLAIN",
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
    hd = 16,
    average_hp_10x = 666,
    ac = 3,
    ev = 15,
    spellbook_id = spellbooks.MST_FENSTRIDER_WITCH,
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 13,
    -- For fenstrider witch, energy costs combine with speed 13 to determine action
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_FENSTRIDER_WITCH",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_FENSTRIDER_WITCH",
}

register.definition(categories.MONSTERS, definition)

return definition
