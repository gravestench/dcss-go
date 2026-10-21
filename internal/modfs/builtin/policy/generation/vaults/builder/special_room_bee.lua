-- Bee rooms use a packed patrolling swarm. Deeper versions substitute a
-- few meliai, while the shared corpse/ambrosia slot keeps source loot.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Lair's effective threat depth is two less than its absolute depth.
local function fill_bees(api)
    local level = api:absolute_depth()

    if api:branch_id() == branches.BRANCH_LAIR then
        level = level - 2
    end

    fill.room(api, "patrolling killer bee", "patrolling queen bee", true)
    api:emit(directives.KMONS, "M = meliai")

    if level > 11 then
        api:emit(directives.NSUBST, "1 = 3:M / *:1")
    end

    api:emit(directives.KITEM,
        "12M = never_decay yak corpse / potion of ambrosia ident:all / " ..
        "nothing w:20")
end

room.fill = fill_bees

return room
