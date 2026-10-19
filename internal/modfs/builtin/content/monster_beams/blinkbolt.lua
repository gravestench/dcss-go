-- living lightning (SPELL_BLINKBOLT) defines a monster beam using
-- zaps.ZAP_BLINKBOLT with power cap 200.
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
    id = "SPELL_BLINKBOLT",
    zap_id = zaps.ZAP_BLINKBOLT,
    name = "living lightning",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    -- living lightning may use a source damage profile; contact policy computes
    -- the actual roll for each target.
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            10,
            1,
            17,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            16,
            1,
            40,
        },
    },
    colour = colours.LIGHTCYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_ELECTRICITY,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
