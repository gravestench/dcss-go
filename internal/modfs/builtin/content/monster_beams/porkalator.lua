local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

-- zap-data.h:_mon_hex_zap gives Porkalator the standard monster hex ray.
local definition = {
    id = spells.SPELL_PORKALATOR,
    zap_id = zaps.ZAP_PORKALATOR,
    name = "",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = false,
    monster_tohit = { kind = "tohit", args = { 0, 1, 3 } },
    colour = colours.RED,
    is_enchantment = true,
    flavour = flavours.BEAM_PORKALATOR,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
