-- juggernaut (MONS_JUGGERNAUT) is a DCSS monster profile with 20 hit dice and
-- speed 15.
-- Its first melee contact is AT_HIT for 80 base damage; combat policy applies
-- defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_JUGGERNAUT",
    status = "defined",
    name = "juggernaut",
    glyph = 67,
    colour_id = "LIGHTGREEN",
    flags = {
        "M_FIGHTER",
        "M_WARM_BLOOD",
        "M_SEE_INVIS",
        "M_SPEAKS",
    },
    xp_modifier = 12,
    genus_id = "MONS_GIANT",
    species_id = "MONS_JUGGERNAUT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- juggernaut offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 80,
        },
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 40,
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
    hd = 20,
    average_hp_10x = 1700,
    ac = 20,
    ev = 5,
    spellbook_id = "MST_NO_SPELLS",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For juggernaut, energy costs combine with speed 15 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 45,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_JUGGERNAUT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_JUGGERNAUT",
}

register.definition(categories.MONSTERS, definition)

return definition
