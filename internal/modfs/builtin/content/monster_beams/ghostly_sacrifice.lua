-- Ghostly Sacrifice converts a living ally into a direct radius-one negative
-- energy blast. Its dice count is five, unlike ordinary Ghostly Fireball.
-- Source: mon-cast.cc:_setup_ghostly_beam and _fire_direct_explosion.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_GHOSTLY_SACRIFICE,
    name = "ghostly fireball",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            5,
            6,
            1,
            13,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            40,
        },
    },
    colour = colours.CYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_NEG,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = true,
    direct_explosion = true,
    explosion_radius = 1,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
