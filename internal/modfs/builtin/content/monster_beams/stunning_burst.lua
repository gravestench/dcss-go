-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- spl-zap.cc:117
-- zap-data.h:936

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_STUNNING_BURST",
    zap_id = zaps.ZAP_STUNNING_BURST,
    name = "stunning burst",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            8,
            1,
            20,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            15,
            1,
            10,
        },
    },
    colour = colours.LIGHTCYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_STUN_BOLT,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 8,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
