-- ghostly fireball (SPELL_GHOSTLY_FIREBALL) defines a monster beam using
-- zaps.ZAP_GHOSTLY_FIREBALL with power cap 200.
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
    id = "SPELL_GHOSTLY_FIREBALL",
    zap_id = zaps.ZAP_GHOSTLY_FIREBALL,
    name = "ghostly fireball",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- ghostly fireball may use a source damage profile; contact policy computes
    -- the actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            6,
            1,
            13,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            40,
        },
    },
    colour = colours.CYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_NEG,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = true,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
