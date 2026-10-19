-- Malmutate (SPELL_MALMUTATE) is an irresistible source enchantment ray.
-- Its hit changes a body instead of rolling damage or checking willpower.
-- Source: mon-cast.cc:mons_spell_beam and zap-data.h:ZAP_MALMUTATE.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_MALMUTATE,
    zap_id = zaps.ZAP_MALMUTATE,
    name = "malmutate",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = false,
    monster_tohit = false,
    colour = colours.ETC_MUTAGENIC,
    is_enchantment = true,
    flavour = flavours.BEAM_MALMUTATE,
    glyph = glyphs.NUM_DCHAR_TYPES,
    can_beam = false,
    is_explosion = false,
    hit_loudness = 0,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
