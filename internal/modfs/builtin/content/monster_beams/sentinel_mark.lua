-- sentinel mark (SPELL_SENTINEL_MARK) defines a monster beam using
-- zaps.ZAP_SENTINEL_MARK with power cap 100.
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
    id = "SPELL_SENTINEL_MARK",
    zap_id = zaps.ZAP_SENTINEL_MARK,
    name = "",
    cap = 100,
    power_hd_factor = 48,
    natural_power = false,
    -- sentinel mark may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = false,
    monster_tohit = {
        kind = "tohit",
        args = {
            0,
            1,
            3,
        },
    },
    colour = colours.BLACK,
    is_enchantment = true,
    flavour = flavours.BEAM_SENTINEL_MARK,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
