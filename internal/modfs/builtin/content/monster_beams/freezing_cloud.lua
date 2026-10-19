-- freezing blast (SPELL_FREEZING_CLOUD) defines a monster beam using
-- zaps.ZAP_FREEZING_BLAST with power cap 200.
-- This is beam metadata; spell selection and a registered effect determine whether it is used.
-- No beam state persists in this definition.

-- mon-cast.cc
-- zap-data.h

local categories = require("constants.catalog")
local zaps = require("constants.zap_ids")
local flavours = require("constants.beam_flavours")
local colours = require("constants.beam_colours")
local glyphs = require("constants.beam_glyphs")

local definition = {
    id = "SPELL_FREEZING_CLOUD",
    zap_id = zaps.ZAP_FREEZING_BLAST,
    name = "freezing blast",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- freezing blast may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            9,
            1,
            11,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            17,
            1,
            25,
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_COLD,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
