-- The fifth-star invocation plants one stationary allied oklob on an
-- aimed open square. Its acid attack remains ordinary monster behavior.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local plants = require("policy.religion.fedhas.active_plants")
local registry = require("policy.abilities.registry")

local grow = {}

-- Source unlock is five stars of Fedhas favor without penance.
function grow.available(ctx, player)
    return costs.available(ctx, player, gods.FEDHAS, 5)
end

-- The aimed plant has the same two-square range as Ballistomycete.
function grow.range()
    return 2
end

-- Invalid aims are free; the resolver only receives a legal cell.
function grow.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 6) then
        return "You do not have enough magic."
    end

    local _, problem = plants.grow_target(ctx, player,
        monsters.MONS_OKLOB_PLANT, input.dx or 0, input.dy or 0)

    return problem
end

-- Successful use charges six MP and generic six piety, whether or not
-- an intervening occupant prevents final placement.
function grow.resolve(ctx, player, intent)
    if costs.failed(ctx, player, 80, 4, 25) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    if plants.grow(ctx, player, monsters.MONS_OKLOB_PLANT,
        intent.dx, intent.dy) then
        ctx:emit("religion", "An oklob plant grows from the ground.")
    else
        ctx:emit("religion", "Nothing happens.")
    end

    costs.spend(ctx, player, 6, costs.piety_cost(ctx, 6))
end

registry.add(abilities.FEDHAS_GROW_OKLOB, {
    name = "Grow Oklob",
    available = grow.available,
    range = grow.range,
    prepare = grow.prepare,
    resolve = grow.resolve,
})

return grow
