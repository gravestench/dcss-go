-- Chain of Chaos creates an automatic-hit ray for each jump. The chosen
-- per-contact flavour comes from the combat policy, not this fixed profile.
-- Source: spl-damage.cc:cast_chain_spell and mon-cast.cc.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_CHAIN_OF_CHAOS,
    name = "arc of chaos",
    cap = 200,
    power_hd_factor = 4,
    natural_power = false,
    monster_damage = {
        kind = "calcdice",
        args = {
            3,
            5,
            1,
            6,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            "AUTOMATIC_HIT",
        },
    },
    colour = colours.ETC_RANDOM,
    is_enchantment = false,
    flavour = flavours.BEAM_CHAOS,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
