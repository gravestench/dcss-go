-- IDs specific to the zap effect family. Shared ECS IDs live in
-- constants.component; spell, monster, and feature IDs come from catalogs.
local ids = {
    component = {
        CONJURE_FLAME = "zap.conjure_flame",
        CONTAMINATION = "zap.contamination",
        IOOD = "zap.iood",
        MAXWELL = "zap.maxwell",
        MAXWELL_VAPORIZE = "zap.maxwell_vaporize",
        NECROTISE = "zap.necrotise",
        PLAYER_CONFUSION = "zap.player_confusion",
        POLAR_VORTEX = "zap.polar_vortex",
        THUNDERBOLT = "zap.thunderbolt",
        WRETCHED = "zap.wretched",
    },
    cloud = {
        COLD = "CLOUD_COLD",
        EMBERS = "CLOUD_EMBERS",
        FIRE = "CLOUD_FIRE",
        MEPHITIC = "CLOUD_MEPHITIC",
        DUST = "CLOUD_DUST",
        TLOC_ENERGY = "CLOUD_TLOC_ENERGY",
        POISON = "CLOUD_POISON",
        GREY_SMOKE = "CLOUD_GREY_SMOKE",
        BLUE_SMOKE = "CLOUD_BLUE_SMOKE",
        BLACK_SMOKE = "CLOUD_BLACK_SMOKE",
        PURPLE_SMOKE = "CLOUD_PURPLE_SMOKE",
    },
}

return ids
