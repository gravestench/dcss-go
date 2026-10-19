-- lance of force (SPELL_FORCE_LANCE) defines a monster beam using
-- zaps.ZAP_FORCE_LANCE with power cap 100.
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
    id = "SPELL_FORCE_LANCE",
    zap_id = zaps.ZAP_FORCE_LANCE,
    name = "lance of force",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    -- lance of force may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            6,
            1,
            15,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            20,
            1,
            20,
        },
    },
    colour = colours.CYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_MMISSILE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 5,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
