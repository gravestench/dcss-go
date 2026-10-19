-- dig (SPELL_DIG) defines a monster beam using zaps.ZAP_DIG with power cap
-- 100.
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
    id = "SPELL_DIG",
    zap_id = zaps.ZAP_DIG,
    name = "",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    -- dig may use a source damage profile; contact policy computes the actual roll
    -- for each target.
    monster_damage = false,
    monster_tohit = false,
    colour = colours.BLACK,
    is_enchantment = true,
    flavour = flavours.BEAM_DIGGING,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 4,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
