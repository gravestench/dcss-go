-- A Lua rule can request a portal after an action changes its owner state.
-- Okawaru uses this when conduct or piety expels the player mid-Duel: the
-- command began in Arena, so only its post-action state reveals the need
-- to return. Go stages and retires the floor through the generic portal.
local component = require("constants.component")
local gods = require("constants.gods")
local travel = require("policy.world.arena.travel")

local forced = {}

-- The pre-action query lets the command retain a rollback checkpoint;
-- the post-action query supplies a concrete portal only after departure.
function forced.pending(ctx)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_ARENA_VISIT)

    if not visit then
        return { potential = false }
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if worship and worship.god_id == gods.OKAWARU and
        (not visit.victory or visit.return_aut > 0) then
        return { potential = true }
    end

    local prepared = travel.prepare_forced(ctx, player, "depart")

    if not prepared or not prepared.portal then
        error("Okawaru departure has no Arena return")
    end

    return {
        potential = true,
        portal = prepared.portal,
    }
end

register.policy({
    id = "world.pending_forced_portal",
    run = forced.pending,
})

return forced
