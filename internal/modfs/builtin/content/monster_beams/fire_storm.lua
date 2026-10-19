-- Fire Storm's zap supplies lava-flavoured dice. Its spell policy chooses
-- the source radius and keeps that choice in the saved target plan.
-- Source: spl-damage.cc:setup_fire_storm and zap-data.h:ZAP_FIRE_STORM.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_FIRE_STORM,
    zap_id = zaps.ZAP_FIRE_STORM,
    name = "great blast of fire",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "calcdice",
        args = {
            8,
            5,
            1,
            2,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            40,
        },
    },
    colour = colours.RED,
    is_enchantment = false,
    flavour = flavours.BEAM_LAVA,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = true,
    direct_explosion = true,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
