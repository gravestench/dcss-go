-- Call Down Damnation uses a separate zap from Hurl Damnation: its blast
-- starts at the selected cell and has the source radius-one footprint.
-- Source: spl-zap.cc and zap-data.h:ZAP_CALL_DOWN_DAMNATION.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_CALL_DOWN_DAMNATION,
    zap_id = zaps.ZAP_CALL_DOWN_DAMNATION,
    name = "damnation",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            15,
            0,
            10,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            20,
        },
    },
    colour = colours.LIGHTRED,
    is_enchantment = false,
    flavour = flavours.BEAM_DAMNATION,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = true,
    direct_explosion = true,
    explosion_radius = 1,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
