-- Malign Offering is a source enchantment beam with its own damage dice.
-- Source: mon-cast.cc:mons_spell_beam, beam.cc:BEAM_MALIGN_OFFERING.
-- Its healing field belongs to the spell policy, not to this fixed profile.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_MALIGN_OFFERING,
    name = "malign offering",
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            7,
            1,
            13,
        },
    },
    colour = colours.BLACK,
    is_enchantment = true,
    flavour = flavours.BEAM_MALIGN_OFFERING,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
