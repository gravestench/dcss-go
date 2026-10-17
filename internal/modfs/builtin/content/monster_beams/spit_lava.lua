-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:106
-- zap-data.h:292

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_SPIT_LAVA",
    zap_id = zaps.ZAP_SPIT_LAVA,
    name = "glob of lava",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            10,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            20,
        },
    },
    colour = colours.RED,
    is_enchantment = false,
    flavour = flavours.BEAM_LAVA,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
