-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:13
-- zap-data.h:411

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_THROW_FLAME",
    zap_id = zaps.ZAP_THROW_FLAME,
    name = "puff of flame",
    cap = 50,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            5,
            1,
            40,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            25,
            1,
            40,
        },
    },
    colour = colours.RED,
    is_enchantment = false,
    flavour = flavours.BEAM_FIRE,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 2,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
