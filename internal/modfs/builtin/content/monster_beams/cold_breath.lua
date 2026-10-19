-- Cold Breath is the source's penetrating frost ray. Draconian casters use
-- two-thirds power; that per-caster exception belongs to the effect file.
-- Source: spl-zap.cc, zap-data.h, mon-cast.cc.

local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_COLD_BREATH,
    zap_id = zaps.ZAP_COLD_BREATH,
    name = "blast of cold",
    cap = 200,
    power_hd_factor = 12,
    natural_power = true,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            0,
            1,
            6,
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
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
