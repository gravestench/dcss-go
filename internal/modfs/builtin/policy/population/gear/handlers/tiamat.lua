-- Tiamat always wears the dragonskin cloak. Keeping its artefact ID here
-- lets a mod replace her loadout without a Go or factory ID switch.
local artefacts = require("ids.artefacts")
local monsters = require("ids.monsters")
local gear = require("policy.population.gear")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Tiamat still rolls her source polearm. The cloak is a separate guaranteed
-- grant, claimed by factory materialization only after she can be placed.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_TIAMAT, depth) or {}

    loadout.body = {
        unique_id = artefacts.UNRAND_DRAGONSKIN,
    }

    return loadout
end

registry.register(monsters.MONS_TIAMAT, handler.loadout)

return handler
