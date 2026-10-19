-- Death Rattle sends a piercing, automatically hitting 2d4 ray through its
-- foe. Cloud placement belongs to the resolver because every crossed cell
-- receives a separately timed miasma cloud after contact damage.
-- Source: mon-cast.cc, SPELL_DEATH_RATTLE; beam.cc:affect_place_clouds.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_DEATH_RATTLE,
    name = "vile air",
    cap = 0,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            4,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            "AUTOMATIC_HIT",
        },
    },
    colour = colours.DARKGREY,
    is_enchantment = false,
    flavour = flavours.BEAM_DEATH_RATTLE,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
