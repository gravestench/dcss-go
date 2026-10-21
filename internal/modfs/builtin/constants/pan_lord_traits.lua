-- IDs for actor-specific Pandemonium lord traits. These are source ghost
-- profile values, not extra monster catalog rows. A generated actor saves
-- its choice so reloading never draws another trait.
local brands = require("constants.weapon_brands")
local attacks = require("constants.monster_attack_types")
local flavours = require("constants.attack_flavours")
local resistance = require("constants.resistance_ids")
local rings = require("constants.monster_cloud_rings")

local traits = {
    fire = resistance.FIRE,
    cold = resistance.COLD,
    electricity = resistance.ELECTRICITY,

    plain = flavours.PLAIN,
    drain_strength = "AF_DRAIN_STR",
    drain_intelligence = "AF_DRAIN_INT",
    drain_dexterity = "AF_DRAIN_DEX",
    drown = "AF_DROWN",
    ensnare = "AF_ENSNARE",
    drain_speed = "AF_DRAIN_SPEED",
    corrode = "AF_CORRODE",
    weakness = "AF_WEAKNESS",
    trample = "AF_TRAMPLE",

}

-- The source excludes HIT and attack types with built-in secondary effects
-- from this initial flavour roll. A later special attack may override it.
traits.plain_attack_types = {
    attacks.BITE,
    attacks.TOUCH,
    attacks.CLAW,
    attacks.PECK,
    attacks.HEADBUTT,
    attacks.PUNCH,
    attacks.KICK,
    attacks.TENTACLE_SLAP,
    attacks.TAIL_SLAP,
    attacks.GORE,
    attacks.TRUNK_SLAP,
}

-- Source weighted forms, kept in source order for deterministic draws.
traits.special_attacks = {
    {
        weight = 10,
        brand = brands.VENOM,
    },

    {
        weight = 10,
        brand = brands.DRAINING,
    },

    {
        weight = 4,
        flavour = traits.drain_strength,
    },

    {
        weight = 4,
        flavour = traits.drain_intelligence,
    },

    {
        weight = 2,
        flavour = traits.drain_dexterity,
    },

    {
        weight = 10,
        flavour = traits.drown,
    },

    {
        weight = 20,
        brand = brands.FLAMING,
    },

    {
        weight = 20,
        brand = brands.FREEZING,
    },

    {
        weight = 20,
        brand = brands.ELECTROCUTION,
    },

    {
        weight = 20,
        brand = brands.VAMPIRISM,
    },

    {
        weight = 20,
        brand = brands.PAIN,
    },

    {
        weight = 20,
        flavour = traits.ensnare,
    },

    {
        weight = 20,
        flavour = traits.drain_speed,
    },

    {
        weight = 20,
        flavour = traits.corrode,
    },

    {
        weight = 20,
        flavour = traits.weakness,
    },

    {
        weight = 40,
        brand = brands.ANTIMAGIC,
    },

    {
        weight = 40,
        brand = brands.DISTORTION,
    },

    {
        weight = 40,
        brand = brands.CHAOS,
    },

    {
        weight = 40,
        flavour = traits.trample,
    },
}

traits.random_rings = {
    {
        weight = 20,
        id = rings.THUNDER,
    },

    {
        weight = 20,
        id = rings.FLAMES,
    },

    {
        weight = 20,
        id = rings.ICE,
    },

    {
        weight = 10,
        id = rings.DRAINING,
    },

    {
        weight = 5,
        id = rings.CHAOS,
    },

    {
        weight = 5,
        id = rings.ACID,
    },

    {
        weight = 5,
        id = rings.MIASMA,
    },

    {
        weight = 5,
        id = rings.MUTATION,
    },
}

-- Validation uses the same source choices as generation. A mod changing
-- the weighted list does not need to maintain a second hand-written set.
traits.valid_attack_types = {
    [attacks.HIT] = true,
    [attacks.STING] = true,
    [attacks.TRAMPLE] = true,
    [attacks.ENGULF] = true,
}
traits.valid_flavours = {
    [traits.plain] = true,
}
traits.valid_brands = {
    [brands.NORMAL] = true,
}
traits.valid_rings = {
    [rings.NONE] = true,
}

for _, id in ipairs(traits.plain_attack_types) do
    traits.valid_attack_types[id] = true
end

for _, form in ipairs(traits.special_attacks) do
    if form.brand then
        traits.valid_brands[form.brand] = true
    end

    if form.flavour then
        traits.valid_flavours[form.flavour] = true
    end
end

for _, ring in ipairs(traits.random_rings) do
    traits.valid_rings[ring.id] = true
end

return traits
