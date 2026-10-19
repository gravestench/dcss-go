-- lindwurm (MONS_LINDWURM) is a DCSS monster profile with 9 hit dice and
-- speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_LINDWURM when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_LINDWURM",
    status = "defined",
    name = "lindwurm",
    glyph = 107,
    colour_id = "LIGHTRED",
    flags = {
        "M_WARM_BLOOD",
    },
    xp_modifier = 13,
    genus_id = "MONS_DRAKE",
    species_id = "MONS_LINDWURM",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 40,
    -- lindwurm offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 10,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 9,
    average_hp_10x = 495,
    ac = 8,
    ev = 6,
    spellbook_id = "MST_LINDWURM",
    leaves_corpse = true,
    shout_id = "S_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For lindwurm, energy costs combine with speed 10 to determine action
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_QUADRUPED",
    tile = {
        id = "TILEP_MONS_LINDWURM",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_LINDWURM",
}

register.definition(categories.MONSTERS, definition)

return definition
