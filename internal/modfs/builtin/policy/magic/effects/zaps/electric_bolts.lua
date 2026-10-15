local spells = require("ids.spells")
local terrain = require("constants.terrain")
local projectile = require("policy.magic.effects.zaps.projectile")

local electric_bolts = {}

local excluded = {
    [terrain.DNGN_OPEN_SEA] = true,
    [terrain.DNGN_LAVA_SEA] = true,
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_GRATE] = true,
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
}

function electric_bolts.bounceable(feature_id)
    -- beam.cc:is_bouncy reflects electricity from solids except metal,
    -- trees, and the level-edge sea features.
    return feature_id ~= nil and not excluded[feature_id]
end

electric_bolts.shock = {
    name = "zap",
    cap = 25,
    beam = true,
    bounce = electric_bolts.bounceable,
    element = "MR_RES_ELEC",
    damage = {
        kind = "dicedef",
        count = 1,
        base = 3,
        numerator = 1,
        denominator = 4,
    },
    hit = {
        base = 8,
        numerator = 1,
        denominator = 7,
    },
}

electric_bolts.lightning_bolt = {
    name = "bolt of lightning",
    cap = 200,
    beam = true,
    bounce = electric_bolts.bounceable,
    element = "MR_RES_ELEC",
    damage = {
        kind = "calcdice",
        count = 1,
        base = 11,
        numerator = 3,
        denominator = 5,
    },
    hit = {
        base = 7,
        numerator = 1,
        denominator = 40,
    },
}

projectile.register(spells.SPELL_SHOCK, electric_bolts.shock)
projectile.register(spells.SPELL_LIGHTNING_BOLT, electric_bolts.lightning_bolt)

return electric_bolts
