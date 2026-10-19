-- Petrifying Cloud fires a damaging, automatic-hit ray through actors and
-- leaves calcifying dust on each travelled cell. The later cloud exposure,
-- rather than the initial ray, applies petrification.
-- Source: spl-zap.cc, zap-data.h, mon-cast.cc, beam.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_PETRIFYING_CLOUD,
    zap_id = zaps.ZAP_PETRIFYING_CLOUD,
    name = "blast of calcifying dust",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            6,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            "AUTOMATIC_HIT",
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_PETRIFYING_CLOUD,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
