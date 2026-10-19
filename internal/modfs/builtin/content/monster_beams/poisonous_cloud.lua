-- blast of poison (SPELL_POISONOUS_CLOUD) defines a monster beam using
-- zaps.ZAP_POISONOUS_CLOUD with power cap 200.
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
    id = "SPELL_POISONOUS_CLOUD",
    zap_id = zaps.ZAP_POISONOUS_CLOUD,
    name = "blast of poison",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- blast of poison may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            3,
            1,
            25,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            18,
            1,
            25,
        },
    },
    colour = colours.LIGHTGREEN,
    is_enchantment = false,
    flavour = flavours.BEAM_POISON,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
