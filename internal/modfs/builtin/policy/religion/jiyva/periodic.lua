-- Theory of operation: one saved clock schedules Jiyva's 100–300 aut
-- source timer. Each firing independently tries active-floor jelly creation
-- and off-floor item consumption. All choices use a named saved RNG stream;
-- no module local remembers game state across save/restore.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local clouds = require("policy.clouds.placement")
local cells = require("policy.religion.jiyva.cells")
local edibility = require("policy.religion.jiyva.items")
local factory = require("policy.population.factory")
local gods = require("constants.gods")
local identity = require("policy.religion.jiyva.identity")
local items = require("policy.inventory.items")
local monsters = require("ids.monsters")
local silence = require("policy.world.silence")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local periodic = {}

local MIN_INTERVAL = 100
local INTERVAL_RANGE = 201
local MAX_BRANCH_DEPTH = 27

-- Construct a finite candidate set from real open cells. Source C++ draws
-- coordinates until one qualifies; filtering first has the same uniform
-- result and avoids an endless loop on a wholly blocked modded floor.
local function spawn_cells(ctx, level_id)
    local width, height = ctx:level_size(level_id)
    local candidates = {}

    if not width or width < 3 or height < 3 then
        return candidates
    end

    for y = 1, height - 2 do
        for x = 1, width - 2 do
            local feature = ctx:cell(level_id, x, y)

            if (feature == terrain.DNGN_FLOOR or
                feature == terrain.DNGN_SHALLOW_WATER) and
                not ctx:actor_at(level_id, x, y) and
                not clouds.at(ctx, level_id, x, y) and
                cells.allowed(ctx, level_id, x, y) then
                candidates[#candidates + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return candidates
end

-- Each successful body is a normal saved actor with a separate Jiyva
-- origin. Remove its chosen cell before the next draw because structural
-- ECS writes may commit only after this Lua system returns.
local function spawn_jellies(ctx, player, due_aut)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return
    end

    local count = 1 + ctx:random(streams.RELIGION, 5)
    local available = spawn_cells(ctx, position.level_id)
    local made = 0

    for _ = 1, count do
        if #available == 0 then
            break
        end

        local index = ctx:random(streams.RELIGION, #available) + 1
        local site = table.remove(available, index)
        local jelly = factory.spawn(ctx, monsters.MONS_JELLY,
            position.level_id, site.x, site.y, {
                attitude = attitudes.GOOD_NEUTRAL,
                god_id = gods.JIYVA,
            })

        ctx:add(jelly, component.JIYVA_SLIME, {
            attitude = attitudes.GOOD_NEUTRAL,
            attempted = true,
        })
        ctx:add(jelly, component.JIYVA_SPAWN, {
            created_aut = due_aut,
        })

        made = made + 1
    end

    if made == 0 or silence.at(ctx, position.level_id,
        position.x, position.y) then
        return
    end

    local message = ctx:random(streams.RELIGION, 3)

    if message == 0 then
        ctx:emit(channels.RELIGION, "Jiyva gurgles merrily.")
    elseif message == 1 then
        local phrase = count > 1 and "a series of splatters" or
            "a splatter"

        ctx:emit(channels.SOUND, "You hear " .. phrase .. ".")
    else
        ctx:emit(channels.RELIGION,
            "Jiyva says: Divide and consume!")
    end
end

-- Map the existing saved levels by source branch and local depth. A chosen
-- unvisited branch/depth is rejected, never generated or silently replaced
-- with some other visited floor.
local function visited_levels(ctx, active_id)
    local visited = {}

    for _, id in ipairs(ctx:level_ids()) do
        if id ~= active_id then
            local branch = ctx:level_branch(id)
            local depth = ctx:level_depth(id)

            if branch and depth then
                visited[branch .. ":" .. depth] = id
            end
        end
    end

    return visited
end

-- Two independent one-in-four gates model source reluctance and the end
-- of a slurp. A qualifying item is removed as a whole even if stacked.
local function digest_floor_stack(ctx, floor)
    for _, entity in ipairs(floor) do
        if edibility.edible(ctx, entity) and
            ctx:random(streams.RELIGION, 4) ~= 0 then
            if ctx:random(streams.RELIGION, 4) == 0 then
                break
            end

            ctx:emit(channels.SOUND,
                "You hear a distant slurping noise.")
            ctx:destroy(entity)
        end
    end
end

-- Rejection samples one coordinate on a selected saved floor. The source
-- can abandon the search before finding an item, so no deterministic scan
-- across all cells may replace these draws.
local function search_level(ctx, level_id)
    local width, height = ctx:level_size(level_id)

    if not width or width < 3 or height < 3 then
        return
    end

    while true do
        if ctx:random(streams.RELIGION, 200) == 0 then
            return
        end

        local x = 1 + ctx:random(streams.RELIGION,
            width - 2)
        local y = 1 + ctx:random(streams.RELIGION,
            height - 2)

        if cells.allowed(ctx, level_id, x, y) then
            local floor = items.at(ctx, {
                level_id = level_id,
                x = x,
                y = y,
            })

            if #floor > 0 then
                digest_floor_stack(ctx, floor)
                return true
            end
        end
    end
end

-- Source jiyva_eat_offlevel_items chooses a branch and a 1–27 depth with
-- bounded rejection. A chosen unvisited floor is rejected, not generated.
local function eat_off_floor(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return
    end

    local visited = visited_levels(ctx, position.level_id)
    local branches = catalog.all(categories.BRANCHES)

    if #branches == 0 then
        return
    end

    while true do
        if ctx:random(streams.RELIGION, 200) == 0 then
            return
        end

        local branch = branches[ctx:random(streams.RELIGION,
            #branches) + 1]
        local depth = ctx:random(streams.RELIGION,
            MAX_BRANCH_DEPTH) + 1
        local level_id = visited[branch.id .. ":" .. depth]

        if level_id then
            if search_level(ctx, level_id) then
                return
            end
        end
    end
end

-- Process every due event crossed by this player action, then save the next
-- interval. Each source timer fires even without Jiyva worship; passives
-- gate the two effects separately at firing time.
function periodic.tick(ctx, player, elapsed_aut)
    if elapsed_aut < 0 then
        error("Jiyva ecology elapsed aut cannot be negative")
    end

    if elapsed_aut == 0 then
        return
    end

    local state = ctx:get(player, component.JIYVA_ECOLOGY)

    if not state then
        state = {
            next_due_aut = ctx:aut() + MIN_INTERVAL +
                ctx:random(streams.RELIGION, INTERVAL_RANGE),
        }
        ctx:add(player, component.JIYVA_ECOLOGY, state)
    end

    local end_aut = ctx:aut() + elapsed_aut

    while state.next_due_aut <= end_aut do
        if identity.passive(ctx, player) then
            if ctx:random(streams.RELIGION, 10) == 0 then
                spawn_jellies(ctx, player, state.next_due_aut)
            end

            if ctx:random(streams.RELIGION, 25) == 0 then
                eat_off_floor(ctx, player)
            end
        end

        state.next_due_aut = state.next_due_aut +
            MIN_INTERVAL + ctx:random(streams.RELIGION,
                INTERVAL_RANGE)
    end

    ctx:set(player, component.JIYVA_ECOLOGY, state)
end

-- Restore accepts a pending timer only on the player and only within the
-- interval the source scheduler could actually have rolled from this aut.
function periodic.validate(ctx, player)
    for _, entity in ipairs(ctx:query({ component.JIYVA_ECOLOGY })) do
        local state = ctx:get(entity, component.JIYVA_ECOLOGY)

        if entity ~= player or state.next_due_aut <= ctx:aut() or
            state.next_due_aut > ctx:aut() +
                MIN_INTERVAL + INTERVAL_RANGE - 1 then
            error("invalid Jiyva ecology timer " .. ctx:id(entity))
        end
    end
end

return periodic
