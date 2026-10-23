local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local mapping = require("policy.world.mapping")
local branches = require("ids.branches")
local gods = require("constants.gods")
local kinds = require("constants.religion_conduct")
local conduct = require("policy.religion.conduct")

local exploration = {}

-- Stochastic rounding preserves fractional regeneration over many newly seen cells.
local function random_divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and
        ctx:random("exploration", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Any active level enables the fixed exploration healing rate used per newly revealed cell.
-- Example: exploration.regeneration(1) gives the exploration regen rate used for revealed cells.
function exploration.regeneration(level)
    return level > 0 and 1 or 0
end

-- Source: view.cc:_do_explore_healing, once for each newly seen cell.
function exploration.on_seen(ctx, count)
    if count < 0 or count % 1 ~= 0 then
        error("newly seen cell count must be nonnegative")
    end

    if count == 0 then
        return
    end

    local player = ctx:player()

    if effects.sum(ctx, player, capabilities.EXPLORE_REGEN) == 0 then
        return
    end

    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)

    if not health or not magic then
        error("exploration regeneration requires player health and magic")
    end

    for _ = 1, count do
        local hp_roll = health.max > 0 and
            ctx:random("exploration", health.max) or 0
        health.current = math.min(health.max,
            health.current + random_divide(ctx, hp_roll, 210))

        local mp_roll = magic.max > 0 and
            ctx:random("exploration", magic.max) or 0
        magic.current = math.min(magic.max,
            magic.current + random_divide(ctx, mp_roll, 135))
    end

    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.MAGIC, magic)
end

-- Source view.cc offers a conduct pulse for each newly seen eligible cell.
-- Temple never counts, and Jiyva does not gain exploration piety in Slime.
-- The view owner supplies only fresh cells, so revisiting old terrain
-- cannot farm devotion after save or floor travel.
local function conduct_on_seen(ctx, count)
    if count == 0 then
        return
    end

    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)
    local branch = position and ctx:level_branch(position.level_id)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if branch == branches.BRANCH_TEMPLE or
        (branch == branches.BRANCH_SLIME and worship and
            worship.god_id == gods.JIYVA) then
        return
    end

    for _ = 1, count do
        conduct.record(ctx, {
            id = kinds.EXPLORATION,
            level = 2500,
            known = true,
        })
    end
end

-- Plan mapping from the same reveal snapshot, then apply explore-regeneration for each new cell.
function exploration.run(ctx, input)
    local mapped = mapping.plan(ctx, input)
    exploration.on_seen(ctx, input.count)
    conduct_on_seen(ctx, input.count)

    return { mapped = mapped }
end

effects.add(mutations.MUT_EXPLORE_REGEN, {
    [capabilities.EXPLORE_REGEN] = exploration.regeneration,
})

register.policy({
    id = "world.on_seen",
    run = exploration.run,
})

return exploration
