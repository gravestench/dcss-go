-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:94
-- zap-data.h:88

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_ENERGY_BOLT",
    zap_id = zaps.ZAP_ENERGY_BOLT,
    name = "bolt of energy",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- mon-cast.cc:1392
    short_name = "energy",
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            20,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            15,
            1,
            30,
        },
    },
    colour = colours.YELLOW,
    is_enchantment = false,
    flavour = flavours.BEAM_DEVASTATION,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
