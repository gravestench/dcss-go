-- ball of steam (SPELL_STEAM_BALL) defines a monster beam using
-- zaps.ZAP_BREATHE_STEAM with power cap 50.
-- This is beam metadata; spell selection and a registered effect determine whether it is used.
-- No beam state persists in this definition.

-- spl-zap.cc
-- zap-data.h

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_STEAM_BALL",
    zap_id = zaps.ZAP_BREATHE_STEAM,
    name = "ball of steam",
    cap = 50,
    power_hd_factor = 12,
    natural_power = false,
    -- ball of steam may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            7,
            1,
            15,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            20,
            1,
            20,
        },
    },
    colour = colours.LIGHTGREY,
    is_enchantment = false,
    flavour = flavours.BEAM_STEAM,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
