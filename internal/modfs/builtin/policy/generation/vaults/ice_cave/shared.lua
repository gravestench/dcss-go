-- The source maps call these few named helpers from their authored DES
-- positions. Loot, monsters, and appearance have separate owners so a
-- modder can read one policy without scanning a giant conditional module.
local appearance = require("policy.generation.vaults.ice_cave.appearance")
local loot = require("policy.generation.vaults.ice_cave.loot")
local monsters = require("policy.generation.vaults.ice_cave.monsters")

local shared = {
    appearance = appearance.exit_and_names,
    common_loot = loot.common,
    necro_loot = loot.necro,
    natural_monsters = monsters.natural,
    undead_monsters = monsters.undead,
    undead_reaper_e = monsters.undead_reaper_e,
    potions_j = loot.potions_j,
    scrolls_d8 = loot.scrolls_d8,
    cavern_j = loot.cavern_j,
    cavern_k = loot.cavern_k,
    fog_8 = appearance.fog_8,
    fog_12 = appearance.fog_12,
    fog_r6 = appearance.fog_r6,
}

return shared
