-- A third-star Fedhas worshipper grows one ballistomycete at an aimed
-- cell. The living actor and spore rules stay in the monster systems.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local plants = require("policy.religion.fedhas.active_plants")
local registry = require("policy.abilities.registry")

local grow = {}

-- Live rank gating lets changed piety or penance affect the next prompt.
function grow.available(ctx, player)
    return costs.available(ctx, player, gods.FEDHAS, 3)
end

-- Source range is two squares, independent of current sight radius.
function grow.range()
    return 2
end

-- Invalid, occupied, or too-distant cells never spend a turn or MP.
function grow.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 4) then
        return "You do not have enough magic."
    end

    local _, problem = plants.grow_target(ctx, player,
        monsters.MONS_BALLISTOMYCETE, input.dx or 0, input.dy or 0)

    return problem
end

-- Failure consumes the action alone. A successful invocation pays costs
-- even when placement becomes blocked after preflight.
function grow.resolve(ctx, player, intent)
    if costs.failed(ctx, player, 60, 4, 25) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    if plants.grow(ctx, player, monsters.MONS_BALLISTOMYCETE,
        intent.dx, intent.dy) then
        ctx:emit("religion", "A ballistomycete grows from the ground.")
    else
        ctx:emit("religion", "Nothing happens.")
    end

    costs.spend(ctx, player, 4, costs.piety_cost(ctx, 4))
end

registry.add(abilities.FEDHAS_GROW_BALLISTOMYCETE, {
    name = "Grow Ballistomycete",
    available = grow.available,
    range = grow.range,
    prepare = grow.prepare,
    resolve = grow.resolve,
})

return grow
