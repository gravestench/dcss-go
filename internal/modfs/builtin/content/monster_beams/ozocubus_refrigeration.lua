-- Ozocubu's Refrigeration uses a four-die cold zap. The area handler
-- applies source adjacency dilution before rolling each victim's dice.
-- Source: spl-zap.cc and zap-data.h:ZAP_REFRIGERATE.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_OZOCUBUS_REFRIGERATION,
    zap_id = zaps.ZAP_REFRIGERATE,
    name = "refrigeration",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "calcdice",
        args = {
            4,
            30,
            4,
            9,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            "AUTOMATIC_HIT",
        },
    },
    colour = colours.LIGHTCYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_COLD,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
