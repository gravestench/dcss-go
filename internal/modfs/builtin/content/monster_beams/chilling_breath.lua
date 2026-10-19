-- Chilling Breath reuses the source frost-breath zap, with its lower cap
-- and louder ray. It is available to mods even without a bundled book slot.
-- Source: spl-zap.cc, zap-data.h, mon-cast.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_CHILLING_BREATH,
    zap_id = zaps.ZAP_BREATHE_FROST,
    name = "freezing breath",
    cap = 50,
    power_hd_factor = 12,
    natural_power = true,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            0,
            1,
            9,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            30,
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_COLD,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 6,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
