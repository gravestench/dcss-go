local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

-- zap-data.h:ZAP_CHAOS_BREATH is a natural, piercing 1d8 chaos ray.
local definition = {
    id = spells.SPELL_CHAOS_BREATH,
    zap_id = zaps.ZAP_CHAOS_BREATH,
    name = "blast of chaos",
    cap = 200,
    power_hd_factor = 12,
    natural_power = true,
    monster_damage = { kind = "dicedef", args = { 1, 0, 1, 8 } },
    monster_tohit = { kind = "tohit", args = { 30 } },
    colour = colours.ETC_RANDOM,
    is_enchantment = false,
    flavour = flavours.BEAM_CHAOS,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
