-- splash of poison (SPELL_SPIT_POISON) defines a monster beam using
-- zaps.ZAP_SPIT_POISON with power cap 50.
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
    id = "SPELL_SPIT_POISON",
    zap_id = zaps.ZAP_SPIT_POISON,
    name = "splash of poison",
    cap = 50,
    power_hd_factor = 12,
    natural_power = false,
    -- splash of poison may use a source damage profile; contact policy computes
    -- the actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            1,
            4,
            1,
            10,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            16,
            1,
            20,
        },
    },
    colour = colours.GREEN,
    is_enchantment = false,
    flavour = flavours.BEAM_POISON,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 1,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
