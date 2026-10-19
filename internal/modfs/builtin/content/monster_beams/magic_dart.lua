-- magic dart (SPELL_MAGIC_DART) defines a monster beam using
-- zaps.ZAP_MAGIC_DART with power cap 25.
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
    id = "SPELL_MAGIC_DART",
    zap_id = zaps.ZAP_MAGIC_DART,
    name = "magic dart",
    cap = 25,
    power_hd_factor = 12,
    natural_power = false,
    -- magic dart may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            4,
            1,
            100,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            "AUTOMATIC_HIT",
        },
    },
    colour = colours.LIGHTMAGENTA,
    is_enchantment = false,
    flavour = flavours.BEAM_MMISSILE,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 1,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
