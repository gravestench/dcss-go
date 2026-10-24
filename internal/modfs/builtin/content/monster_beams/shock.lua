-- Source Shock uses a short, reflecting electric beam. Its monster damage
-- and accuracy are the zap-data.h monster calculators; the shared beam
-- owner handles tracing, contact, resistance, and reflection at cast time.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_SHOCK,
    zap_id = zaps.ZAP_SHOCK,
    name = "zap",
    cap = 25,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            1,
            8,
            1,
            20,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            17,
            1,
            20,
        },
    },
    colour = colours.LIGHTCYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_ELECTRICITY,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 1,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
