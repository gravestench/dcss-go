-- This entrance puts source simulacra around the timed archway. The same
-- difficulty used for its gate chooses the bodies, so the decoration and
-- destination cannot disagree after save and restore.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local entry = require("policy.generation.vaults.ice_cave_entry.shared")
local monsters = require("policy.generation.vaults.ice_cave.monsters")

local map = {}

-- The source declares the portal first, then the two simulacrum groups.
-- Their actor draws remain with ordinary vault population.
function map.site_1(api)
    local hard = entry.portal(api)
    local simul = monsters.simulacrum_sets(hard)

    api:emit(directives.MONS, simul.mocking)
    api:emit(directives.MONS, simul.savage)
end

-- The source thins or strengthens slot 1 by branch and local depth.
-- Keep that substitution next to its original DES site.
function map.site_2(api)
    local branch = api:branch_id()

    if branch == branches.BRANCH_DUNGEON then
        if api:depth() < 12 then
            api:emit(directives.SUBST, "1 = 1.")
        else
            api:emit(directives.SUBST, "1 = 112")
        end

    elseif branch == branches.BRANCH_LAIR then
        if api:depth() < 3 then
            api:emit(directives.SUBST, "1 = 2...")
        else
            api:emit(directives.SUBST, "1 = 2.")
        end

    elseif branch == branches.BRANCH_ORC then
        api:emit(directives.SUBST, "1 = 112")

    else
        api:emit(directives.SUBST, "1 = 12")
    end
end

return map
