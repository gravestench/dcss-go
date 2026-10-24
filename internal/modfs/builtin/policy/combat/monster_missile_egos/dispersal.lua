-- A dispersal hit samples two nearby legal player landings and selects
-- whichever is farther from the thrower. Stasis and magical anchoring
-- block the effect before either landing draw is consumed.
local nearby = require("policy.combat.dispersal")
local translocation = require("policy.scrolls.translocation")

local dispersal = {}

local function distance(a, b)
    return math.max(math.abs(a.x - b.x),
        math.abs(a.y - b.y))
end

-- Source ranged-attack.cc only displaces after positive contact damage.
function dispersal.apply(ctx, attacker, _, _, damage)
    if damage <= 0 then
        return
    end

    local player = ctx:player()

    if translocation.restriction(ctx, player, true) then
        return
    end

    local position = ctx:get(player, "core.position")
    local source = ctx:get(attacker, "core.position")
    local legal = function(x, y)
        return translocation.can_land(ctx, player,
            position.level_id, x, y)
    end
    local first = nearby.nearby_space(ctx, position, legal)
    local second = nearby.nearby_space(ctx, position, legal)

    if not first or not second then
        return
    end

    local destination = distance(second, source) >
        distance(first, source) and second or first

    ctx:move_actor(player, position.level_id,
        destination.x, destination.y)
end

return dispersal
