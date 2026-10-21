-- Source fog-machine names are stable DES input. Resolve them once to the
-- same registered cloud IDs used by combat and world cloud policy.
local clouds = require("ids.clouds")

return {
    ["black smoke"] = clouds.CLOUD_BLACK_SMOKE,
    ["acidic fog"] = clouds.CLOUD_ACID,
    ["blessed fire"] = clouds.CLOUD_HOLY,
    ["blue smoke"] = clouds.CLOUD_BLUE_SMOKE,
    ["calcifying dust"] = clouds.CLOUD_PETRIFY,
    ["flame"] = clouds.CLOUD_FIRE,
    ["degeneration"] = clouds.CLOUD_DEGENERATION,
    ["foul pestilence"] = clouds.CLOUD_MIASMA,
    ["freezing vapour"] = clouds.CLOUD_COLD,
    ["grey smoke"] = clouds.CLOUD_GREY_SMOKE,
    ["magical condensation"] = clouds.CLOUD_MAGIC_TRAIL,
    ["mutagenic fog"] = clouds.CLOUD_MUTAGENIC,
    ["noxious fumes"] = clouds.CLOUD_MEPHITIC,
    ["poison gas"] = clouds.CLOUD_POISON,
    ["purple smoke"] = clouds.CLOUD_PURPLE_SMOKE,
    ["rain"] = clouds.CLOUD_RAIN,
    ["salt"] = clouds.CLOUD_SALT,
    ["seething chaos"] = clouds.CLOUD_CHAOS,
    ["sparse dust"] = clouds.CLOUD_DUST,
    ["steam"] = clouds.CLOUD_STEAM,
    ["thin mist"] = clouds.CLOUD_MIST,
    ["thunder"] = clouds.CLOUD_STORM,
    ["translocational energy"] = clouds.CLOUD_TLOC_ENERGY,
    ["white fluffiness"] = clouds.CLOUD_FLUFFY,
}
