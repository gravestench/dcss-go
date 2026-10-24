-- Mephitic Cloud has no zap-data entry: mon-cast.cc builds a zero-damage
-- stinking explosion directly. This profile supplies range and area aim;
-- the spell effect below places the actual confusing clouds.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local spells = require("ids.spells")

local definition = {
    id = spells.SPELL_MEPHITIC_CLOUD,
    name = "stinking cloud",
    cap = 100,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            1,
            0,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            14,
            1,
            30,
        },
    },
    colour = colours.GREEN,
    is_enchantment = false,
    flavour = flavours.BEAM_MEPHITIC,
    can_beam = false,
    is_explosion = true,
    explosion_radius = 1,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
