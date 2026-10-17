-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:23
-- zap-data.h:902

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_STONE_ARROW",
    zap_id = zaps.ZAP_STONE_ARROW,
    name = "stone arrow",
    cap = 50,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            5,
            1,
            10,
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
    colour = colours.LIGHTGREY,
    is_enchantment = false,
    flavour = flavours.BEAM_MMISSILE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 3,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
