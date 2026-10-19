-- salamander tyrant (MONS_SALAMANDER_TYRANT) is a DCSS monster profile with
-- 15 hit dice and speed 10.
-- Its first melee contact is AT_HIT for 15 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SALAMANDER_TYRANT when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SALAMANDER_TYRANT",
    status = "defined",
    name = "salamander tyrant",
    glyph = 78,
    colour_id = "RED",
    flags = {
        "M_WARM_BLOOD",
    },
    resistances = {
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_NAGA",
    species_id = "MONS_SALAMANDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- salamander tyrant offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_FIRE",
            damage = 15,
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
    average_hp_10x = 675,
    ac = 5,
    ev = 7,
    spellbook_id = "MST_SALAMANDER_TYRANT",
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS_LAVA",
    speed = 10,
    -- For salamander tyrant, energy costs combine with speed 10 to determine
    -- action cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 7,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_NAGA",
    tile = {
        id = "TILEP_MONS_SALAMANDER_TYRANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
