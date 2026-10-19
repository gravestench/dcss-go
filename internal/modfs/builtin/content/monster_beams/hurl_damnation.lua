-- damnation (SPELL_HURL_DAMNATION) defines a monster beam using
-- zaps.ZAP_HURL_DAMNATION with power cap 200.
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
    id = "SPELL_HURL_DAMNATION",
    zap_id = zaps.ZAP_HURL_DAMNATION,
    name = "damnation",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- damnation may use a source damage profile; contact policy computes the
    -- actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            20,
            0,
            10,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            24,
        },
    },
    colour = colours.LIGHTRED,
    is_enchantment = false,
    flavour = flavours.BEAM_DAMNATION,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = true,
    hit_loudness = 9,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
