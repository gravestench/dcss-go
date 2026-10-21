-- All large Depths-side Zot entrances share the source's five encounter
-- definitions. Their DES files own PLACE and ORIENT because selection must
-- know those facts before any placement-time Lua hook can run.
local directives = require("constants.vault_directives")

local shared = {}

-- Emit the same keyed gate and guard pools at each map's source script
-- position. One function prevents the fourteen authored entrance shapes
-- from drifting into different guardian rules as content is edited.
local function entry_setup(api)
    api:emit(directives.KFEAT, "O = enter_zot")
    api:emit(directives.MONS, "patrolling base draconian")
    api:emit(directives.MONS,
        "fire dragon / ice dragon / storm dragon / " ..
        "shadow dragon / bone dragon / golden dragon")
    api:emit(directives.MONS, "patrolling nonbase draconian")
    api:emit(directives.KMONS,
        "0 = ettin / tengu warrior / glowing shapeshifter w:5 / " ..
        "stone giant w:12 / spriggan berserker w:8 / hell knight w:5")
    api:emit(directives.KMONS,
        "9 = fire giant w:12 / titan w:8 / vampire knight / " ..
        "spriggan air mage w:8 / deep troll earth mage w:8 / " ..
        "tengu reaver / deep elf high priest w:12 / lich w:2")
end

shared.entry_setup = entry_setup

return shared
