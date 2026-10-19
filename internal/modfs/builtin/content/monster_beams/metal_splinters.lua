-- Metal Splinters is a piercing physical ray. Fragmentation rolls armour
-- three times on each target instead of using an elemental resistance.
-- Source: spl-zap.cc, zap-data.h, beam.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_METAL_SPLINTERS,
    zap_id = zaps.ZAP_METAL_SPLINTERS,
    name = "spray of metal splinters",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            20,
            1,
            20,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            19,
            1,
            30,
        },
    },
    colour = colours.CYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_FRAG,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
