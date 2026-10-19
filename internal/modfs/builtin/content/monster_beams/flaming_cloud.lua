-- Flaming Cloud is natural dragon breath: a piercing fire ray that seeds
-- short-lived fire on its path and a larger fire field at its endpoint.
-- Source: spl-zap.cc, zap-data.h, mon-cast.cc, beam.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_FLAMING_CLOUD,
    zap_id = zaps.ZAP_FLAMING_CLOUD,
    name = "blast of flame",
    cap = 200,
    power_hd_factor = 12,
    natural_power = true,
    monster_damage = {
        kind = "dicedef",
        args = {
            1,
            0,
            1,
            8,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            30,
        },
    },
    colour = colours.RED,
    is_enchantment = false,
    flavour = flavours.BEAM_FIRE,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
