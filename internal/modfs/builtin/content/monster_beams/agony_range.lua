-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:90
-- zap-data.h:1124

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_AGONY_RANGE",
    zap_id = zaps.ZAP_AGONY_RANGE,
    name = "agony",
    cap = 100,
    power_hd_factor = 18,
    natural_power = false,
    monster_damage = false,
    monster_tohit = {
        kind = "tohit",
        args = {
            0,
            1,
            3,
        },
    },
    colour = colours.BLACK,
    is_enchantment = true,
    flavour = flavours.BEAM_AGONY,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
