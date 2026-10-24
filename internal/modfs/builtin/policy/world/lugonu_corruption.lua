-- Theory of operation: Lugonu marks a floor once with saved nexus ECS
-- entities. A first pass permanently changes its grid; each nexus then
-- emits neutral Abyss servants for its remaining clock. Expired records
-- stay on the floor to prevent a second use after save and restore.
local abyss = require("policy.world.abyss")
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local habitat = require("policy.combat.monster_habitat")
local magic_power = require("policy.magic.power")
local roll = require("policy.combat.roll")
local servants = require("policy.combat.monster_corruption_servants")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local terrain = require("constants.terrain")
local terrain_pass = require("policy.world.lugonu_corruption.terrain")

local corruption = {}
local stream = streams.LUGONU_CORRUPTION

-- The source random_range helper averages two inclusive draws. Its
-- negative lower bound can produce no auxiliary seeds at all.
local function average_range(ctx, low, high)
    local width = high - low + 1
    return low + roll.average_two(ctx, stream, width)
end

-- One central nexus always exists. Auxiliary attempts may fail because
-- only bare floor within four cells can accept another seed.
local function make_seeds(ctx, position, power)
    local high = math.floor(power * 140 / 100)
    local low = math.floor(power * 40 / 100)
    local count = average_range(ctx, -1,
        math.min(2 + math.floor(power / 110), 4))
    local seeds = {
        {
            x = position.x,
            y = position.y,
            remaining_aut = high + 300,
        },
    }

    for _ = 1, count do
        for _ = 1, 100 do
            local x = position.x + ctx:random(stream, 9) - 4
            local y = position.y + ctx:random(stream, 9) - 4
            local occupied = false

            for _, seed in ipairs(seeds) do
                occupied = occupied or seed.x == x and seed.y == y
            end

            if not occupied and
                ctx:cell(position.level_id, x, y) ==
                    terrain.DNGN_FLOOR then
                seeds[#seeds + 1] = {
                    x = x,
                    y = y,
                    remaining_aut = average_range(ctx, low, high) + 300,
                }

                break
            end
        end
    end

    return seeds
end

-- The first nexus remains after its clock reaches zero. No later piety
-- or worship change can turn this same level into a fresh target.
function corruption.corrupted(ctx, level_id)
    if level_id == abyss.level_id then
        return true
    end

    for _, entity in ipairs(ctx:query({
        component.LUGONU_CORRUPTION_NEXUS,
    })) do
        local nexus = ctx:get(entity,
            component.LUGONU_CORRUPTION_NEXUS)

        if nexus.level_id == level_id then
            return true
        end
    end

    return false
end

-- Source servant offsets are positive draws with independent signs.
-- This reaches cells around, rather than only adjacent to, a nexus.
local function servant_offset(ctx)
    local magnitude = roll.average_three(ctx, stream, 4) +
        ctx:random(stream, 3)

    if ctx:random(stream, 2) == 0 then
        return magnitude
    end

    return -magnitude
end

-- Thirty placement attempts can fail without inventing a monster. The
-- catalog picker already excludes holy and Abyss-only species.
local function spawn_near(ctx, player, nexus)
    local invocations = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, 25)

    if ctx:random(stream, 200 + invocations) < 100 then
        return true
    end

    for _ = 1, 30 do
        local x = nexus.x + servant_offset(ctx)
        local y = nexus.y + servant_offset(ctx)
        local kind = servants.pick(ctx)

        if not ctx:actor_at(nexus.level_id, x, y) and
            habitat.kind_at(ctx, kind, nexus.level_id, x, y) then
            local spawned = summons.spawn(ctx, player, gods.LUGONU,
                kind, 5, nil, {
                    anchor = {
                        level_id = nexus.level_id,
                        x = nexus.x,
                        y = nexus.y,
                    },
                    exact = {
                        x = x,
                        y = y,
                    },
                    attitude = attitudes.NEUTRAL,
                    source_category = categories.GODS,
                    silent_failure = true,
                })

            if spawned then
                return true
            end
        end
    end

    return false
end

-- Spend a proportional number of attempts using the nexus's prior
-- duration as source probability. The saved record never disappears.
local function advance_nexus(ctx, player, entity, nexus, elapsed)
    if nexus.remaining_aut < 1 or elapsed < 1 then
        return
    end

    local attempts = math.max(1,
        math.floor((elapsed + ctx:random(stream, 5)) / 5))

    for _ = 1, attempts do
        if ctx:random(stream, 4000) < nexus.remaining_aut and
            not spawn_near(ctx, player, nexus) then
            break
        end
    end

    nexus.remaining_aut = math.max(0,
        nexus.remaining_aut - elapsed)
    ctx:set(entity, component.LUGONU_CORRUPTION_NEXUS,
        nexus)
end

-- Normal turns only age the active source floor. Leaving and returning
-- keeps the nexus clock and permanent terrain where they were saved.
function corruption.advance(ctx, input)
    local player = ctx:player()
    local level_id = input.level_id
    local elapsed = input.elapsed_aut or 0

    for _, entity in ipairs(ctx:query({
        component.LUGONU_CORRUPTION_NEXUS,
    })) do
        local nexus = ctx:get(entity,
            component.LUGONU_CORRUPTION_NEXUS)

        if nexus.level_id == level_id then
            advance_nexus(ctx, player, entity, nexus, elapsed)
        end
    end

    return {}
end

-- Install all markers before changing terrain, so the same seed list
-- controls the initial grid and later servant events.
function corruption.apply(ctx, player, power)
    local position = ctx:get(player, component.POSITION)

    if corruption.corrupted(ctx, position.level_id) then
        error("this level is already corrupted")
    end

    local seeds = make_seeds(ctx, position, power)

    for _, seed in ipairs(seeds) do
        local entity = ctx:create()

        ctx:add(entity, component.LUGONU_CORRUPTION_NEXUS, {
            level_id = position.level_id,
            x = seed.x,
            y = seed.y,
            remaining_aut = seed.remaining_aut,
        })
    end

    ctx:emit("religion", "Lugonu's Hand of Corruption reaches out!")
    terrain_pass.apply(ctx, position.level_id,
        position.x, position.y, seeds)
    corruption.advance(ctx, {
        level_id = position.level_id,
        elapsed_aut = 300,
    })
end

register.policy({
    id = "world.lugonu_corruption",
    run = corruption.advance,
})

return corruption
