-- crystal spear (SPELL_LEHUDIBS_CRYSTAL_SPEAR) defines a monster beam using
-- zaps.ZAP_LEHUDIBS_CRYSTAL_SPEAR with power cap 200.
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
    id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
    zap_id = zaps.ZAP_LEHUDIBS_CRYSTAL_SPEAR,
    name = "crystal spear",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- crystal spear may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            16,
            1,
            10,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            22,
            1,
            20,
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_MMISSILE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 8,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
