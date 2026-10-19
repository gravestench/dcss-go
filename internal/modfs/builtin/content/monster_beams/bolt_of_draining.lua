-- bolt of negative energy (SPELL_BOLT_OF_DRAINING) defines a monster beam
-- using zaps.ZAP_BOLT_OF_DRAINING with power cap 200.
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
    id = "SPELL_BOLT_OF_DRAINING",
    zap_id = zaps.ZAP_BOLT_OF_DRAINING,
    name = "bolt of negative energy",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- bolt of negative energy may use a source damage profile; contact policy
    -- computes the actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            9,
            1,
            13,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            16,
            1,
            35,
        },
    },
    colour = colours.DARKGREY,
    is_enchantment = false,
    flavour = flavours.BEAM_NEG,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
