-- Fedhas surrounds a deserter with hostile plants on visible empty rings.
-- Terrain stays in the grid; every summoned plant is a normal saved ECS
-- actor with Fedhas as its source. Dense floors get near and far rings,
-- while a cramped floor gets a few eligible adjacent attackers.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local sight = require("constants.spell_range")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")

local plants = {}
local MAX_DISTANCE_SQUARED = sight.LOS_RADIUS ^ 2 + 1
local TWO_PI = 2 * math.pi
local SPACIOUS_RING_MIN = 24
local MIN_ARCS = 3
local ARC_SPAN = 6
local MIN_NEAR_PLANTS = 2
local NEAR_PLANT_SPAN = 7

-- Group visible, empty, nonsolid cells by the source's approximate
-- Euclidean ring thresholds r * (r + 1), starting with adjacent cells.
local function rings(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local grouped = {}

    for radius = 1, sight.LOS_RADIUS do
        grouped[radius] = {}
    end

    for dy = -sight.LOS_RADIUS, sight.LOS_RADIUS do
        for dx = -sight.LOS_RADIUS, sight.LOS_RADIUS do
            local distance = dx * dx + dy * dy
            local x = origin.x + dx
            local y = origin.y + dy

            if distance > 0 and distance <= MAX_DISTANCE_SQUARED and
                ctx:walkable(origin.level_id, x, y) and
                not ctx:actor_at(origin.level_id, x, y) and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, sight.LOS_RADIUS, x, y) then
                for radius = 1, sight.LOS_RADIUS do
                    if distance <= radius * (radius + 1) then
                        grouped[radius][#grouped[radius] + 1] = {
                            x = x,
                            y = y,
                        }
                        break
                    end
                end
            end
        end
    end

    return grouped, origin
end

-- Source shuffle_array randomizes cells before an arc can claim one.
-- The Fisher-Yates order stays independent of ECS query order.
local function shuffle(ctx, cells)
    for index = #cells, 2, -1 do
        local other = ctx:random(streams.CARDS, index) + 1

        cells[index], cells[other] = cells[other], cells[index]
    end
end

-- Divide a circle into equal arcs, with north and the positive x axis
-- handled without depending on the host Lua version's atan2 support.
local function arc(origin, cell, count)
    local dx = cell.x - origin.x
    local dy = cell.y - origin.y
    local angle

    if dx == 0 then
        angle = dy > 0 and math.pi / 2 or 3 * math.pi / 2
    else
        angle = math.atan(dy / dx)

        if dx < 0 then
            angle = angle + math.pi
        elseif angle < 0 then
            angle = angle + TWO_PI
        end
    end

    local width = TWO_PI / count

    return math.floor((angle + width / 2) / width) % count + 1
end

-- Spawn at the authored ring cell rather than near the player. A failed
-- habitat or occupancy check consumes that ring choice, as source does.
local function spawn(ctx, player, kind_id, cell)
    return summons.spawn(ctx, player, gods.FEDHAS, kind_id, 0, nil, {
        attitude = attitudes.HOSTILE,
        source_category = categories.GODS,
        stream = streams.CARDS,
        silent_failure = true,
        silent_hostility = true,
        exact = {
            x = cell.x,
            y = cell.y,
        },
    })
end

-- One near ring fills with ordinary plants. A distant, spacious ring
-- gets one oklob per selected arc instead of a single clump.
local function spacious(ctx, player, grouped, origin, outer)
    local made = false
    local near = grouped[1]

    shuffle(ctx, near)

    for _, cell in ipairs(near) do
        made = spawn(ctx, player, monsters.MONS_PLANT, cell) or made
    end

    local far = grouped[outer]
    local arc_count = MIN_ARCS + ctx:random(streams.CARDS, ARC_SPAN)
    local used = {}

    shuffle(ctx, far)

    for _, cell in ipairs(far) do
        local index = arc(origin, cell, arc_count)

        if not used[index] then
            used[index] = true
            made = spawn(ctx, player,
                monsters.MONS_OKLOB_PLANT, cell) or made
        end
    end

    return made
end

-- Path searches may enter an occupied hostile cell only when that monster
-- can move. A stationary blocker never opens a route for a new plant.
local function traversable_actor(ctx, entity, player)
    if not targets.enemy(ctx, player, entity) then
        return false
    end

    local actor = ctx:get(entity, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY then
            return false
        end
    end

    return true
end

-- Mirror source _path_distance from each adjacent candidate to its
-- nearest visible hostile. Other candidate cells and the player's cell
-- cannot be transit nodes in that search.
local function nearest_hostile(ctx, player, origin,
    start, hostiles, exclusions)
    local queue = {
        { x = start.x, y = start.y, distance = 0 },
    }
    local seen = {}
    local head = 1

    seen[start.x .. ":" .. start.y] = true

    while head <= #queue do
        local current = queue[head]

        head = head + 1

        for _, hostile in ipairs(hostiles) do
            if current.x == hostile.x and
                current.y == hostile.y then
                return current.distance
            end
        end

        for dy = -1, 1 do
            for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    local x = current.x + dx
                    local y = current.y + dy
                    local key = x .. ":" .. y
                    local actor = ctx:actor_at(origin.level_id, x, y)

                    if not seen[key] and not exclusions[key] and
                        (x ~= origin.x or y ~= origin.y) and
                        math.max(math.abs(x - origin.x),
                            math.abs(y - origin.y)) <=
                            sight.LOS_RADIUS and
                        ctx:walkable(origin.level_id, x, y) and
                        ctx:visible(origin.level_id,
                            origin.x, origin.y, sight.LOS_RADIUS,
                            x, y) and
                        (not actor or
                            traversable_actor(ctx, actor, player)) then
                        seen[key] = true
                        queue[#queue + 1] = {
                            x = x,
                            y = y,
                            distance = current.distance + 1,
                        }
                    end
                end
            end
        end
    end

    return math.huge
end

-- When little floor is open, source picks two to eight adjacent cells.
-- With no other visible hostile, shuffle; otherwise prefer cells farther
-- from existing hostiles so the new plants surround another approach.
local function cramped(ctx, player, near, origin)
    local wanted = math.min(#near,
        MIN_NEAR_PLANTS + ctx:random(streams.CARDS,
            NEAR_PLANT_SPAN))
    local hostiles = {}

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if entity ~= player and health.current > 0 and
            position.level_id == origin.level_id and
            math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y)) <=
                sight.LOS_RADIUS and
            targets.enemy(ctx, player, entity) and
            ctx:visible(origin.level_id, origin.x, origin.y,
                sight.LOS_RADIUS, position.x, position.y) then
            hostiles[#hostiles + 1] = position
        end
    end

    if wanted < #near and #hostiles == 0 then
        shuffle(ctx, near)
    elseif wanted < #near then
        local exclusions = {}
        local distances = {}

        for _, cell in ipairs(near) do
            exclusions[cell.x .. ":" .. cell.y] = true
        end

        for _, cell in ipairs(near) do
            distances[cell] = nearest_hostile(ctx, player,
                origin, cell, hostiles, exclusions)
        end

        table.sort(near, function(left, right)
            local left_distance = distances[left]
            local right_distance = distances[right]

            if left_distance ~= right_distance then
                return left_distance < right_distance
            end

            if left.y ~= right.y then
                return left.y < right.y
            end

            return left.x < right.x
        end)
    end
    local made = false

    for index = #near - wanted + 1, #near do
        local kind_id = ctx:random(streams.CARDS, 2) == 0 and
            monsters.MONS_WANDERING_MUSHROOM or
            monsters.MONS_OKLOB_PLANT

        made = spawn(ctx, player, kind_id, near[index]) or made
    end

    return made
end

-- A successful encirclement ends this wrath action; an empty or blocked
-- floor lets the card continue its remaining retribution behavior.
function plants.apply(ctx, player)
    local grouped, origin = rings(ctx, player)
    local outer = 4

    for radius = 5, sight.LOS_RADIUS do
        if #grouped[radius] > #grouped[outer] then
            outer = radius
        end
    end

    local made = false

    if #grouped[outer] > SPACIOUS_RING_MIN then
        made = spacious(ctx, player, grouped, origin, outer)
    elseif #grouped[1] > 0 then
        made = cramped(ctx, player, grouped[1], origin)
    end

    if made then
        ctx:emit("religion", "Plants grow around you in an ominous manner.")
    end

    return not made
end

return plants
