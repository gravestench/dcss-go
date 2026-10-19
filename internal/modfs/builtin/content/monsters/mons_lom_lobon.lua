-- Lom Lobon (MONS_LOM_LOBON) is a DCSS monster profile with 19 hit dice and
-- speed 10.
-- Its first melee contact is AT_HIT for 40 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_LOM_LOBON when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_LOM_LOBON",
    status = "defined",
    name = "Lom Lobon",
    glyph = 38,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_UNIQUE",
        "M_FIGHTER",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_FLIES",
        "M_TALL_TILE",
        "M_GENDER_NEUTRAL",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 3,
        },
        {
            id = "MR_RES_ELEC",
            level = 3,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_PANDEMONIUM_LORD",
    species_id = "MONS_LOM_LOBON",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 5000,
    -- Lom Lobon offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_ANTIMAGIC",
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
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 19,
    average_hp_10x = 3895,
    ac = 10,
    ev = 20,
    spellbook_id = "MST_LOM_LOBON",
    shout_id = "S_SCREAM",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Lom Lobon, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_LOM_LOBON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
