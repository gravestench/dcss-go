-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:37
-- zap-data.h:1158

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_MINDBURST",
    zap_id = zaps.ZAP_MINDBURST,
    name = "",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "calcdice",
        args = {
            1,
            12,
            1,
            4,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            50,
            0,
            1,
        },
    },
    colour = colours.BLACK,
    is_enchantment = true,
    flavour = flavours.BEAM_MINDBURST,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 6,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
