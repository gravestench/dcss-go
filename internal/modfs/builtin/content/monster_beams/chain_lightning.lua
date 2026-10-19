-- Chain Lightning's source zap uses thunder: half its damage resists as
-- electricity while the other half remains sonic. Beam AC is halved.
-- Monster casts use three dice sized by 27 + power/12, unlike the player's
-- calculated total. The chain policy supplies each arc's reduced size.
-- Source: zap-data.h:ZAP_CHAIN_LIGHTNING and fight.cc.
local categories = require("constants.catalog")
local colours = require("constants.beam_colours")
local flavours = require("constants.beam_flavours")
local glyphs = require("constants.beam_glyphs")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local definition = {
    id = spells.SPELL_CHAIN_LIGHTNING,
    zap_id = zaps.ZAP_CHAIN_LIGHTNING,
    name = "bolt of lightning",
    cap = 200,
    power_hd_factor = 12,
    natural_power = false,
    monster_damage = {
        kind = "dicedef",
        args = {
            3,
            27,
            1,
            12,
        },
    },
    monster_tohit = {
        kind = "tohit",
        args = {
            "AUTOMATIC_HIT",
        },
    },
    colour = colours.LIGHTCYAN,
    is_enchantment = false,
    flavour = flavours.BEAM_THUNDER,
    glyph = glyphs.DCHAR_FIRED_ZAP,
    can_beam = true,
    is_explosion = false,
    hit_loudness = 10,
}

register.definition(categories.MONSTER_BEAMS, definition)

return definition
