-- puff of flame (SPELL_THROW_FLAME) defines a monster beam using
-- zaps.ZAP_THROW_FLAME with power cap 50.
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
    id = "SPELL_THROW_FLAME",
    zap_id = zaps.ZAP_THROW_FLAME,
    name = "puff of flame",
    cap = 50,
    power_hd_factor = 12,
    natural_power = false,
    -- puff of flame may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            5,
            1,
            40,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            25,
            1,
            40,
        },
    },
    colour = colours.RED,
    is_enchantment = false,
    flavour = flavours.BEAM_FIRE,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 2,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
