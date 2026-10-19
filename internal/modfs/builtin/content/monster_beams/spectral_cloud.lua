-- Spectral Cloud is constructed directly in mon-cast.cc rather than through
-- a zap. Its ray pierces but deals no immediate damage; saved spectral mist
-- owns later damage and possible spectral summons.
-- Source: mon-cast.cc, beam.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_SPECTRAL_CLOUD,
    name = "spectral mist",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            0,
            1,
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
    colour = colours.CYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_MMISSILE,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
