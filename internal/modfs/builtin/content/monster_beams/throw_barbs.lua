-- Source: zap-data.h:ZAP_THROW_BARBS. The volley is a single-target
-- physical missile; armour applies but elemental resistance does not.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_THROW_BARBS,
    zap_id = zaps.ZAP_THROW_BARBS,
    name = "volley of spikes",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            2,
            13,
            0,
            1,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            27,
        },
    },
    colour = colours.LIGHTGREY,
    is_enchantment = false,
    flavour = flavours.BEAM_MMISSILE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
