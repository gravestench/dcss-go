-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:38
-- zap-data.h:1192

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_THROW_ICICLE",
    zap_id = zaps.ZAP_THROW_ICICLE,
    name = "shard of ice",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            8,
            1,
            11,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            17,
            1,
            25,
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_ICE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 4,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
