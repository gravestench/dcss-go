-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:21
-- zap-data.h:549

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_PRIMAL_WAVE",
    zap_id = zaps.ZAP_PRIMAL_WAVE,
    name = "torrent of water",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            6,
            1,
            12,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            14,
            1,
            35,
        },
    },
    colour = colours.LIGHTBLUE,
    is_enchantment = false,
    flavour = flavours.BEAM_WATER,
    glyph = glyphs.DCHAR_WAVY,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 6,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
