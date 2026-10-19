-- splash of acid (SPELL_SPIT_ACID) defines a monster beam using
-- zaps.ZAP_SPIT_ACID with power cap 200.
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
    id = "SPELL_SPIT_ACID",
    zap_id = zaps.ZAP_SPIT_ACID,
    name = "splash of acid",
    cap = 200,
    power_hd_factor = 12,
    natural_power = true,
    -- splash of acid may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            14,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            20,
            1,
            4,
        },
    },
    colour = colours.YELLOW,
    is_enchantment = false,
    flavour = flavours.BEAM_ACID,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 6,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
