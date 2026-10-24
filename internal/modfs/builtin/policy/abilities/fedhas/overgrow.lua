-- Overgrow replaces one aimed wall or tree and its visible neighboring
-- features with short-lived plant allies. The permanent grid edits use
-- the level owner; only actors use ECS summon expiry.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local plants = require("policy.religion.fedhas.active_plants")
local registry = require("policy.abilities.registry")
local vision = require("policy.character.vision")

local overgrow = {}

-- A worshipper needs four stars for this terrain-changing invocation.
function overgrow.available(ctx, player)
    return costs.available(ctx, player, gods.FEDHAS, 4)
end

-- LOS_MAX_RANGE tracks the player's live sight, including mutations.
function overgrow.range(_, ctx, player)
    return vision.radius(ctx, player)
end

-- Source rejects an invisible, protected, or unbreakable aim before time.
function overgrow.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 8) then
        return "You do not have enough magic."
    end

    local _, problem = plants.overgrow_target(ctx, player,
        input.dx or 0, input.dy or 0,
        overgrow.range(nil, ctx, player))

    return problem
end

-- One invocation failure covers the entire affected cluster, then one
-- resource charge pays for all terrain destruction and resulting plants.
function overgrow.resolve(ctx, player, intent)
    if costs.failed(ctx, player, 70, 5, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    plants.overgrow(ctx, player, intent.dx, intent.dy,
        overgrow.range(nil, ctx, player))
    costs.spend(ctx, player, 8, costs.piety_cost(ctx, 12))
end

registry.add(abilities.FEDHAS_OVERGROW, {
    name = "Overgrow",
    available = overgrow.available,
    range = overgrow.range,
    prepare = overgrow.prepare,
    resolve = overgrow.resolve,
})

return overgrow
