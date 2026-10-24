-- Fedhas' second-star invocation raises finite friendly briar actors in
-- every open neighboring cell. Those actors use ordinary thorn combat.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local plants = require("policy.religion.fedhas.active_plants")
local registry = require("policy.abilities.registry")

local wall = {}

-- Worship, piety, penance, and silence all affect the live ability menu.
function wall.available(ctx, player)
    return costs.available(ctx, player, gods.FEDHAS, 2)
end

-- No space and insufficient MP abort before source failure or turn timing.
function wall.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, 3) then
        return "You do not have enough magic."
    end

    if #plants.briar_cells(ctx, player) == 0 then
        return "There isn't enough space to grow briars here."
    end
end

-- Failure spends time alone. Success grows every eligible patch and pays
-- the source 3 MP plus generic two-point piety cost once for the wall.
function wall.resolve(ctx, player)
    if costs.failed(ctx, player, 30, 6, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    if plants.wall_of_briars(ctx, player) == 0 then
        ctx:emit("religion", "Nothing happens.")
    end

    costs.spend(ctx, player, 3, costs.piety_cost(ctx, 2))
end

registry.add(abilities.FEDHAS_WALL_OF_BRIARS, {
    name = "Wall of Briars",
    available = wall.available,
    prepare = wall.prepare,
    resolve = wall.resolve,
})

return wall
