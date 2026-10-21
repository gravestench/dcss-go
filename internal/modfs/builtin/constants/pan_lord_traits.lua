-- IDs for actor-specific Pandemonium lord traits. These are source ghost
-- profile values, not extra monster catalog rows. A generated actor saves
-- its choice so reloading never draws another trait.
local brands = require("constants.weapon_brands")
local attacks = require("constants.monster_attack_types")
local resistance = require("constants.resistance_ids")

local traits = {
    fire = resistance.FIRE,
    cold = resistance.COLD,
    electricity = resistance.ELECTRICITY,

    plain = "AF_PLAIN",
    drain_strength = "AF_DRAIN_STR",
    drain_intelligence = "AF_DRAIN_INT",
    drain_dexterity = "AF_DRAIN_DEX",
    drown = "AF_DROWN",
    ensnare = "AF_ENSNARE",
    drain_speed = "AF_DRAIN_SPEED",
    corrode = "AF_CORRODE",
    weakness = "AF_WEAKNESS",
    trample = "AF_TRAMPLE",

    no_ring = "ENCH_NONE",
    ring_thunder = "ENCH_RING_OF_THUNDER",
    ring_flames = "ENCH_RING_OF_FLAMES",
    ring_ice = "ENCH_RING_OF_ICE",
    ring_draining = "ENCH_RING_OF_DRAINING",
    ring_chaos = "ENCH_RING_OF_CHAOS",
    ring_acid = "ENCH_RING_OF_ACID",
    ring_miasma = "ENCH_RING_OF_MIASMA",
    ring_mutation = "ENCH_RING_OF_MUTATION",
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
        id = traits.ring_thunder,
    },

    {
        weight = 20,
        id = traits.ring_flames,
    },

    {
        weight = 20,
        id = traits.ring_ice,
    },

    {
        weight = 10,
        id = traits.ring_draining,
    },

    {
        weight = 5,
        id = traits.ring_chaos,
    },

    {
        weight = 5,
        id = traits.ring_acid,
    },

    {
        weight = 5,
        id = traits.ring_miasma,
    },

    {
        weight = 5,
        id = traits.ring_mutation,
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
    [traits.no_ring] = true,
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
