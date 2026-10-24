-- Cerebov always begins with his named sword in source monster gear.
-- The factory materializes the unique and records its run history.
local artefacts = require("ids.artefacts")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Keep the signature as a catalog ID so its item kind and properties have
-- one owner. The later disarmed-Cerebov state will gate this selection.
function handler.loadout()
    return {
        primary = {
            unique_id = artefacts.UNRAND_CEREBOV,
        },
    }
end

registry.register(monsters.MONS_CEREBOV, handler.loadout)

return handler
