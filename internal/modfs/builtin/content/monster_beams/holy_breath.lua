-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:108
-- zap-data.h:224

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_HOLY_BREATH",
    zap_id = zaps.ZAP_HOLY_BREATH,
    name = "blast of cleansing flame",
    cap = 200,
    power_hd_factor = 12,
    natural_power = true,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            0,
            1,
            12,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            18,
            1,
            25,
        },
    },
    colour = colours.ETC_HOLY,
    is_enchantment = false,
    flavour = flavours.BEAM_HOLY,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
