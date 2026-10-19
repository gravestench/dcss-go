-- Bai Suzhen (MONS_BAI_SUZHEN_DRAGON) is a DCSS monster profile with 20 hit
-- dice and speed 10.
-- Its first melee contact is AT_BITE for 30 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_BAI_SUZHEN_DRAGON when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_BAI_SUZHEN_DRAGON",
    status = "defined",
    name = "Bai Suzhen",
    glyph = 68,
    colour_id = "ETC_ELECTRICITY",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_COLD_BLOOD",
        "M_SPEAKS",
        "M_FEMALE",
        "M_FLIES",
        "M_THUNDER_RING",
    },
    resistances = {
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_STORM_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 100,
    -- Bai Suzhen offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 30,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 16,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 16,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 20,
    average_hp_10x = 1850,
    ac = 22,
    ev = 4,
    spellbook_id = spellbooks.MST_BAI_SUZHEN_DRAGON,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Bai Suzhen, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_BAI_SUZHEN_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
