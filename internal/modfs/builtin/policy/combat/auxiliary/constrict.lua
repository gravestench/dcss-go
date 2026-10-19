local attacks = require("constants.auxiliary_attacks")
local auxiliary = require("policy.combat.auxiliary")
local component = require("constants.component")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local constrict = {
    id = attacks.CONSTRICT.id,
    order = attacks.CONSTRICT.order,
    chance = 100,
    scale_with_level = false,
    contact_only = true,
    mutation_ids = {
        mutations.MUT_CONSTRICTING_TAIL,
        mutations.MUT_TENTACLE_ARMS,
    },
}

-- A constricting auxiliary attack needs a free constriction slot and a reachable target.
function constrict.available(ctx, input)
    local player = ctx:player()
    local tail = levels.effective(ctx, player,
        mutations.MUT_CONSTRICTING_TAIL) >= 2
    local tentacles = levels.effective(ctx, player,
        mutations.MUT_TENTACLE_ARMS) > 0 and input.free_tentacles > 0

    return input.target ~= nil and (tail or tentacles) and
        input.can_see and input.adjacent and not input.confused and
        not input.target_immune_to_constriction and
        input.player_size >= input.target_size and
        not ctx:has(input.target, component.PLAYER_CONSTRICTION) and
        not ctx:has(input.target, component.MONSTER_VILE_CLUTCH) and
        not ctx:has(input.target, component.GRASPING_ROOTS) and
        (input.existing_grips == 0 or input.free_tentacles > 0)
end

-- Example: constrict.describe() with Constrict selected -> grab profile with zero contact damage
-- Constriction has one contact message; later damage happens on elapsed player actions.
function constrict.describe()
    return {
        name = "grab",
        verb = "grab",
        base = 0,
    }
end

-- The player-constriction component records the grip for later turn damage and escape checks.
function constrict.on_hit(ctx, target)
    ctx:add(target, component.PLAYER_CONSTRICTION, {
        by = ctx:player(),
        held_aut = 0,
        escape_attempts = 0,
    })

    return 0
end

auxiliary.register(constrict)

return constrict
