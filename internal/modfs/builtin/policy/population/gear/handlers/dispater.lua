-- Dispater's staff is guaranteed source gear, even though the artefact
-- catalog excludes it from ordinary random item generation.
local artefacts = require("ids.artefacts")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- The shared item generator supplies the staff's kind, plus, and unique
-- identity after this handler chooses the named source artefact.
function handler.loadout()
    return {
        primary = {
            unique_id = artefacts.UNRAND_DISPATER,
        },
    }
end

registry.register(monsters.MONS_DISPATER, handler.loadout)

return handler
