-- pain (SPELL_PAIN) defines a monster beam using zaps.ZAP_PAIN with power cap
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
    id = "SPELL_PAIN",
    zap_id = zaps.ZAP_PAIN,
    name = "",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    minimum_power = 150,
    -- pain may use a source damage profile; contact policy computes the actual
    -- roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            1,
            7,
            1,
            20,
        },
    },
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
    flavour = flavours.BEAM_PAIN,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 1,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
