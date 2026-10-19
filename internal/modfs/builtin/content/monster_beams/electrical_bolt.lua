-- bolt of electricity (SPELL_ELECTRICAL_BOLT) defines a monster beam using
-- zaps.ZAP_ELECTRICAL_BOLT with power cap 200.
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
    id = "SPELL_ELECTRICAL_BOLT",
    zap_id = zaps.ZAP_ELECTRICAL_BOLT,
    name = "bolt of electricity",
    cap = 200,
    power_hd_factor = 12,
    natural_power = true,
    -- bolt of electricity may use a source damage profile; contact policy computes
    -- the actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            3,
            1,
            12,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            35,
        },
    },
    colour = colours.LIGHTCYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_ELECTRICITY,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
