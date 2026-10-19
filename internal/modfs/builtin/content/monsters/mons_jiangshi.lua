-- jiangshi (MONS_JIANGSHI) is a DCSS monster profile with 10 hit dice and
-- speed 18.
-- Its first melee contact is AT_CLAW for 27 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_JIANGSHI",
    status = "defined",
    name = "jiangshi",
    glyph = 86,
    colour_id = "YELLOW",
    flags = {
        "M_FIGHTER",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_JIANGSHI",
    species_id = "MONS_VAMPIRE",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 80,
    -- jiangshi offers AT_CLAW as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_VAMPIRIC",
            damage = 27,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_VAMPIRIC",
            damage = 27,
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
    hd = 10,
    average_hp_10x = 650,
    ac = 10,
    ev = 10,
    spellbook_id = "MST_NO_SPELLS",
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 18,
    -- For jiangshi, energy costs combine with speed 18 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 6,
        swim = 6,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_JIANGSHI",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
