local spells = require("ids.spells")
local projectile = require("policy.magic.effects.zaps.projectile")

local physical = {}

-- Source: zap-data.h at e60ba3568b0c26447ad36ec5c7b963eb04b2778f.
-- The player-side damage and hit calculators are transcribed below.
physical.zaps = {
    [spells.SPELL_SANDBLAST] = {
        name = "blast of sand",
        cap = 50,
        damage = {
            kind = "dicedef",
            count = 2,
            base = 4,
            numerator = 1,
            denominator = 3,
        },
        hit = {
            base = 15,
            numerator = 1,
            denominator = 10,
        },
        ac_rule = "triple",
    },
    [spells.SPELL_STONE_ARROW] = {
        name = "stone arrow",
        cap = 50,
        damage = {
            kind = "dicedef",
            count = 3,
            base = 7,
            numerator = 1,
            denominator = 8,
        },
        hit = {
            base = 8,
            numerator = 1,
            denominator = 10,
        },
    },
    [spells.SPELL_IRON_SHOT] = {
        name = "iron shot",
        cap = 200,
        damage = {
            kind = "calcdice",
            count = 9,
            base = 15,
            numerator = 3,
            denominator = 4,
        },
        hit = {
            base = 7,
            numerator = 1,
            denominator = 15,
        },
    },
    [spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR] = {
        name = "crystal spear",
        cap = 200,
        damage = {
            kind = "calcdice",
            count = 10,
            base = 23,
            numerator = 1,
            denominator = 1,
        },
        hit = {
            base = 10,
            numerator = 1,
            denominator = 15,
        },
    },
}

for id, spec in pairs(physical.zaps) do
    projectile.register(id, spec)
end

return physical
