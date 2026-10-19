-- Major Destruction's electric orb bursts around its endpoint. Source:
-- zap-data.h:ZAP_ORB_OF_ELECTRICITY and beam.cc:ex_size = 2.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_ORB_OF_ELECTRICITY,
    zap_id = zaps.ZAP_ORB_OF_ELECTRICITY,
    name = "orb of electricity",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            7,
            1,
            9,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            40,
        },
    },
    colour = colours.LIGHTBLUE,
    is_enchantment = false,
    flavour = flavours.BEAM_ELECTRICITY,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = false,
    is_explosion = true,
    explosion_radius = 2,
    hit_loudness = 6,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
