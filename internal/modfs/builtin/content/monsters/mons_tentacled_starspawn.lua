-- tentacled starspawn (MONS_TENTACLED_STARSPAWN) is a DCSS monster profile
-- with 16 hit dice and speed 10.
-- Its first melee contact is AT_BITE for 40 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_TENTACLED_STARSPAWN when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_TENTACLED_STARSPAWN",
    status = "defined",
    name = "tentacled starspawn",
    glyph = 88,
    colour_id = "LIGHTCYAN",
    xp_modifier = 20,
    genus_id = "MONS_TENTACLED_STARSPAWN",
    species_id = "MONS_TENTACLED_STARSPAWN",
    holiness = {
        "MH_NONLIVING",
    },
    willpower = 120,
    -- tentacled starspawn offers AT_BITE as its first contact; later slots are
    -- tried by the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_TENTACLE_SLAP",
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
    average_hp_10x = 880,
    ac = 5,
    ev = 5,
    spellbook_id = spellbooks.MST_TENTACLED_STARSPAWN,
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For tentacled starspawn, energy costs combine with speed 10 to determine
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_TENTACLED_STARSPAWN",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
