-- Sting's poisoned arrow is a short, nonpiercing zap. Keep its source
-- monster damage and accuracy here so every caster uses the same profile.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_STING,
    zap_id = zaps.ZAP_STING,
    name = "sting",
    cap = 25,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            1,
            6,
            1,
            25,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            60,
            0,
            1,
        },
    },
    colour = colours.GREEN,
    is_enchantment = false,
    flavour = flavours.BEAM_POISON_ARROW,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 1,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
