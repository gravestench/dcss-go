-- Source-authored conditional directives stay at their DES call sites.
-- These helpers share only decisions repeated verbatim across cave maps.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")
local monsters = require("policy.generation.vaults.ice_cave.monsters")

local conditional = {}

-- Each cavern independently chooses a natural or undead population.
-- This draw is separate from the entrance's fixed easy/hard choice.
function conditional.cavern_monsters(api)
    if api:coinflip() then
        monsters.undead(api)
    else
        monsters.natural(api)
    end
end

-- The three source caverns share exactly the same J/K room substitutions.
function conditional.cavern_rooms(api)
    if difficulty.hard(api) then
        api:emit(directives.NSUBST, "J = 6 / 5.")
        return
    end

    api:emit(directives.SUBST, "J : JJK")
    api:emit(directives.NSUBST, "J = 2=5 / 5., K = 6 / .")
end

-- Two statue gardens start with the same cold loot and simulacrum slots.
-- Their later room substitutions remain in their individual map modules.
function conditional.garden_start(api)
    local loot = require("policy.generation.vaults.ice_cave.loot")
    local simul = monsters.simulacrum_sets(difficulty.hard(api))

    loot.common(api)
    api:emit(directives.MONS, simul.savage)
    api:emit(directives.MONS, simul.cruel)
end

-- Both gardens use the source weighted random monster list, but their
-- authored placement substitutions differ and are kept beside each map.
function conditional.garden_roster(api)
    local simul = monsters.simulacrum_sets(difficulty.hard(api))

    if difficulty.hard(api) then
        api:emit(directives.MONS,
            "orange crystal statue, freezing wraith, white very ugly thing")
        monsters.record_random_list(api,
            monsters.weighted_entries(simul.savage, 12) ..
            " / " .. monsters.weighted_entries(simul.cruel, 5) ..
            " / freezing wraith")
        return
    end

    api:emit(directives.MONS,
        "ice statue, freezing wraith, white ugly thing")
    monsters.record_random_list(api,
        monsters.weighted_entries(simul.savage, 16) ..
        " / " .. simul.cruel)
end

return conditional
