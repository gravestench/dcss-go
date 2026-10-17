-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:29
-- zap-data.h:711

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_VENOM_BOLT",
    zap_id = zaps.ZAP_VENOM_BOLT,
    name = "bolt of poison",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            6,
            1,
            13,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            19,
            1,
            20,
        },
    },
    colour = colours.LIGHTGREEN,
    is_enchantment = false,
    flavour = flavours.BEAM_POISON,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 5,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
