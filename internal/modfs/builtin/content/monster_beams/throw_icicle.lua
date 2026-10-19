-- shard of ice (SPELL_THROW_ICICLE) defines a monster beam using
-- zaps.ZAP_THROW_ICICLE with power cap 100.
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
    id = "SPELL_THROW_ICICLE",
    zap_id = zaps.ZAP_THROW_ICICLE,
    name = "shard of ice",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    -- shard of ice may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            8,
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
    flavour = flavours.BEAM_ICE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 4,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
