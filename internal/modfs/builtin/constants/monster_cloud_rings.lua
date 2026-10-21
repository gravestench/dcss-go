-- One source enchantment ID names each cloud ring, whether it comes from
-- a monster species flag or a generated Pan lord profile. Cloud placement
-- reads this table; definitions never need a parallel switch statement.
local clouds = require("ids.clouds")
local flags = require("constants.monster_flags")

local rings = {
    NONE = "ENCH_NONE",
    THUNDER = "ENCH_RING_OF_THUNDER",
    FLAMES = "ENCH_RING_OF_FLAMES",
    CHAOS = "ENCH_RING_OF_CHAOS",
    MUTATION = "ENCH_RING_OF_MUTATION",
    FOG = "ENCH_RING_OF_FOG",
    ICE = "ENCH_RING_OF_ICE",
    DRAINING = "ENCH_RING_OF_DRAINING",
    ACID = "ENCH_RING_OF_ACID",
    MIASMA = "ENCH_RING_OF_MIASMA",
}

rings.CLOUD_FOR_RING = {
    [rings.THUNDER] = clouds.CLOUD_STORM,
    [rings.FLAMES] = clouds.CLOUD_FIRE,
    [rings.CHAOS] = clouds.CLOUD_CHAOS,
    [rings.MUTATION] = clouds.CLOUD_MUTAGENIC,
    [rings.FOG] = clouds.CLOUD_GREY_SMOKE,
    [rings.ICE] = clouds.CLOUD_COLD,
    [rings.DRAINING] = clouds.CLOUD_NEGATIVE_ENERGY,
    [rings.ACID] = clouds.CLOUD_ACID,
    [rings.MIASMA] = clouds.CLOUD_MIASMA,
}

-- Source mon-place.cc grants these three species flags their permanent
-- ring enchantment as soon as the actor enters the level.
rings.FOR_FLAG = {
    [flags.FIRE_RING] = rings.FLAMES,
    [flags.THUNDER_RING] = rings.THUNDER,
    [flags.MIASMA_RING] = rings.MIASMA,
}

return rings
