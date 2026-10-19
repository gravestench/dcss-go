-- sap magic (SPELL_SAP_MAGIC) defines a monster beam using zaps.ZAP_SAP_MAGIC
-- with power cap 100.
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
    id = "SPELL_SAP_MAGIC",
    zap_id = zaps.ZAP_SAP_MAGIC,
    name = "",
    cap = 100,
    power_hd_factor = 10,
    natural_power = false,
    -- sap magic may use a source damage profile; contact policy computes the
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
    flavour = flavours.BEAM_SAP_MAGIC,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
