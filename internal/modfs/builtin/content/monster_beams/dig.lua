-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:55
-- zap-data.h:589

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_DIG",
    zap_id = zaps.ZAP_DIG,
    name = "",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = false,
    monster_tohit = false,
    colour = colours.BLACK,
    is_enchantment = true,
    flavour = flavours.BEAM_DIGGING,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 4,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
