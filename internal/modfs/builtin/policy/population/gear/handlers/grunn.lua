-- Grunn normally gets its source-weighted polearm. A rare winning roll
-- replaces it with the scythe of Curses through the shared item generator.
local artefacts = require("ids.artefacts")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")
local registry = require("policy.population.gear.registry")

local handler = {}

-- Keep the ordinary polearm ready if Curses has already been generated;
-- the chance still consumes its monster gear draw in that case.
function handler.loadout(ctx, depth)
    local loadout = gear.ordinary_loadout(ctx,
        monsters.MONS_GRUNN, depth) or {}

    if gear.chance_unique(ctx, artefacts.UNRAND_CURSES, 100) then
        loadout.primary = {
            unique_id = artefacts.UNRAND_CURSES,
        }
    end

    return loadout
end

registry.register(monsters.MONS_GRUNN, handler.loadout)

return handler
