-- Ensnare is a stream of webbing with source projectile accuracy. The beam
-- carries no HP damage; its effect module applies the web only on contact.
-- The source beam is assembled in beam.cc for SPELL_ENSNARE.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_ENSNARE,
    name = "stream of webbing",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = false,
    monster_tohit = {
        kind = "tohit",
        args = {
            22,
            1,
            20,
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_ENSNARE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
