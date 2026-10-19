-- bolt of energy (SPELL_ENERGY_BOLT) defines a monster beam using
-- zaps.ZAP_ENERGY_BOLT with power cap 200.
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
    id = "SPELL_ENERGY_BOLT",
    zap_id = zaps.ZAP_ENERGY_BOLT,
    name = "bolt of energy",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- mon-cast.cc
    short_name = "energy",
    -- bolt of energy may use a source damage profile; contact policy computes the
    -- actual roll for each target.
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
