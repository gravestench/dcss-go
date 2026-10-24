-- Flame Tongue is the source short fire bolt. Its small cap and 3-die
-- monster damage distinguish it from Throw Flame despite shared element.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_FLAME_TONGUE,
    zap_id = zaps.ZAP_FLAME_TONGUE,
    name = "flame tongue",
    cap = 25,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            3,
            1,
            12,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            7,
            1,
            6,
        },
    },
    colour = colours.RED,
    is_enchantment = false,
    flavour = flavours.BEAM_FIRE,
    glyph = glyphs.DCHAR_FIRED_BOLT,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 1,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
