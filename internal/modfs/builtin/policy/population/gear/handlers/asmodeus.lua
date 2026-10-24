-- Asmodeus carries the Sceptre of Asmodeus as a guaranteed source weapon.
-- Its artefact definition remains the single owner of item properties.
local artefacts = require("ids.artefacts")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Return a name rather than a copied item declaration so generated loot
-- and later player use read the same artefact catalog record.
function handler.loadout()
    return {
        primary = {
            unique_id = artefacts.UNRAND_ASMODEUS,
        },
    }
end

registry.register(monsters.MONS_ASMODEUS, handler.loadout)

return handler
