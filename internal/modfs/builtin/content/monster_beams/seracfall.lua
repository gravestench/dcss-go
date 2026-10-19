-- Seracfall uses the source Iceblast zap. Its spell logic multiplies spell
-- HD by 18, then hurls the resulting radius-one blast from a simulacrum.
-- Source: mon-cast.cc:_setup_seracfall_beam and zap-data.h:ZAP_ICEBLAST.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_SERACFALL,
    zap_id = zaps.ZAP_ICEBLAST,
    name = "seracfall",
    cap = 200,
    power_hd_factor = 18,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            6,
            1,
            12,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            40,
        },
    },
    colour = colours.WHITE,
    is_enchantment = false,
    flavour = flavours.BEAM_ICE,
    glyph = glyphs.DCHAR_FIRED_MISSILE,
    can_beam = false,
    is_explosion = true,
    explosion_radius = 1,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
