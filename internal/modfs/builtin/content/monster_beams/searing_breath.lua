-- Searing Breath has a steeper damage scale than Fire Breath. Xtahua's
-- three-halves power adjustment is chosen by its effect at cast time.
-- Source: spl-zap.cc, zap-data.h, mon-cast.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_SEARING_BREATH,
    zap_id = zaps.ZAP_SEARING_BREATH,
    name = "searing blast",
    cap = 200,
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
