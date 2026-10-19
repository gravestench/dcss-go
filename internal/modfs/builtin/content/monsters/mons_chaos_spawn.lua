-- chaos spawn (MONS_CHAOS_SPAWN) is a DCSS monster profile with 6 hit dice
-- and speed 10.
-- Its first melee contact is AT_RANDOM for 19 base damage; combat policy
-- applies defenses and status effects.
-- MST_NO_SPELLS supplies no AI spell slots for this profile.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_CHAOS_SPAWN",
    status = "defined",
    name = "chaos spawn",
    glyph = 52,
    colour_id = "ETC_RANDOM",
    xp_modifier = 12,
    genus_id = "MONS_CHAOS_SPAWN",
    species_id = "MONS_CHAOS_SPAWN",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 60,
    -- chaos spawn offers AT_RANDOM as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_RANDOM",
            flavour_id = "AF_CHAOTIC",
            damage = 19,
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
    hd = 6,
    average_hp_10x = 330,
    ac = 7,
    ev = 12,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    shout_id = "S_RANDOM",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For chaos spawn, energy costs combine with speed 10 to determine action
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
    shape_id = "MON_SHAPE_MISC",
    tile = {
        id = "TILEP_MONS_CHAOS_SPAWN",
        variation_id = "TVARY_RANDOM",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
