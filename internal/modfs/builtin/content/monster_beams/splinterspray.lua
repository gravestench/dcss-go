-- Splinterspray shares the fragment contact rule with Metal Splinters but
-- keeps its weaker wooden damage, lower accuracy, and missile glyph.
-- Source: spl-zap.cc, zap-data.h, beam.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_SPLINTERSPRAY,
    zap_id = zaps.ZAP_SPLINTERSPRAY,
    name = "spray of wooden splinters",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            15,
            1,
            20,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            17,
            1,
            30,
        },
    },
    colour = colours.BROWN,
    is_enchantment = false,
    flavour = flavours.BEAM_FRAG,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
