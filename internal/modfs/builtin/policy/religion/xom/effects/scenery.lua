-- Xom's scenery act changes ordinary saved terrain. Visible fountains and
-- complete door groups take priority; if none exist, he leaves permanent
-- altars or temporary butterflies near the player instead.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local events = require("ids.xom_events")
local gods = require("constants.gods")
local items = require("policy.inventory.items")
local monsters = require("ids.monsters")
local noise = require("policy.world.noise")
local streams = require("constants.rng_streams")
local summon = require("policy.magic.effects.summons.common")
local terrain = require("constants.terrain")
local vision = require("policy.character.vision")

local effect = {}

local open_to_closed = {
    [terrain.DNGN_OPEN_DOOR] = terrain.DNGN_CLOSED_DOOR,
    [terrain.DNGN_OPEN_CLEAR_DOOR] = terrain.DNGN_CLOSED_CLEAR_DOOR,
}

local closed_to_open = {
    [terrain.DNGN_CLOSED_DOOR] = terrain.DNGN_OPEN_DOOR,
    [terrain.DNGN_CLOSED_CLEAR_DOOR] = terrain.DNGN_OPEN_CLEAR_DOOR,
}

local fountain = {
    [terrain.DNGN_FOUNTAIN_BLUE] = true,
    [terrain.DNGN_FOUNTAIN_MAGIC] = true,
    [terrain.DNGN_FOUNTAIN_DRY] = true,
    [terrain.DNGN_FOUNTAIN_BLOOD] = true,
}

local neighbors = {
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = 0, y = -1 },
    { x = 0, y = 1 },
}

-- A coordinate key prevents connected doors from being collected twice
-- when several of their cells are visible in the source vision iterator.
local function key(x, y)
    return x .. ":" .. y
end

-- A gate is one connected group of identical door features. Include its
-- offscreen cells too; moving only the visible part would split the gate.
local function door_group(ctx, level_id, start, feature)
    local pending = { start }
    local visited = { [key(start.x, start.y)] = true }
    local group = {}
    local index = 1

    while index <= #pending do
        local point = pending[index]
        index = index + 1
        group[#group + 1] = point

        for _, offset in ipairs(neighbors) do
            local x = point.x + offset.x
            local y = point.y + offset.y
            local cell_key = key(x, y)

            if not visited[cell_key] and
                ctx:cell(level_id, x, y) == feature then
                visited[cell_key] = true
                pending[#pending + 1] = { x = x, y = y }
            end
        end
    end

    return group
end

-- An open gate cannot close on an actor or loose floor item. Closed gates
-- may open even when something occupies their cells in a modded map.
local function blocked_gate(ctx, level_id, group)
    for _, point in ipairs(group) do
        local position = {
            level_id = level_id,
            x = point.x,
            y = point.y,
        }

        if ctx:actor_at(level_id, point.x, point.y) or
            #items.at(ctx, position) > 0 then
            return true
        end
    end

    return false
end

-- Keep source candidate order: fountains first, then open and closed
-- gates. Blood and magic fountains may remain unchanged when applied.
function effect.candidates(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        return {}
    end

    local level_id = origin.level_id
    local radius = vision.radius(ctx, player)
    local visible = ctx:visible_cells(level_id,
        origin.x, origin.y, radius)
    local fountains = {}
    local open_doors = {}
    local closed_doors = {}
    local visited = {}

    for _, point in ipairs(visible) do
        local feature = ctx:cell(level_id, point.x, point.y)

        if fountain[feature] then
            fountains[#fountains + 1] = point
        elseif (open_to_closed[feature] or
            closed_to_open[feature]) and
            not visited[key(point.x, point.y)] then
            local group = door_group(ctx, level_id, point, feature)

            for _, member in ipairs(group) do
                visited[key(member.x, member.y)] = true
            end

            if closed_to_open[feature] or
                not blocked_gate(ctx, level_id, group) then
                local destination = open_to_closed[feature] and
                    open_doors or closed_doors

                for _, member in ipairs(group) do
                    destination[#destination + 1] = member
                end
            end
        end
    end

    for _, point in ipairs(open_doors) do
        fountains[#fountains + 1] = point
    end

    for _, point in ipairs(closed_doors) do
        fountains[#fountains + 1] = point
    end

    return fountains
end

-- The source's nested random2 can yield zero at either level. Treat a
-- zero bound as a certain zero rather than asking the Lua RNG to draw it.
local function random2(ctx, stream, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random(stream, bound)
end

-- The source samples a 13 by 13 square at most 150 times. Its first pass
-- rejects adjacent cells, then it retries with adjacent cells allowed.
-- Checking no-trans sight matches valid_blink_destination for this use.
local function near_floor(ctx, origin, radius, stream, adjacent)
    local tried = {}

    for _ = 1, 150 do
        local x = origin.x + ctx:random(stream, 13) - 6
        local y = origin.y + ctx:random(stream, 13) - 6
        local cell_key = key(x, y)

        if not tried[cell_key] then
            tried[cell_key] = true
            local distance = math.max(math.abs(x - origin.x),
                math.abs(y - origin.y))

            if (adjacent or distance > 1) and
                ctx:cell(origin.level_id, x, y) ==
                    terrain.DNGN_FLOOR and
                not ctx:actor_at(origin.level_id, x, y) and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, radius, x, y) then
                return x, y
            end
        end
    end
end

-- Permanent Xom altars use their own terrain ID, like the pocket Abyss's
-- Lugonu altar. Prayer can identify their patron without a DES record.
local function place_altars(ctx, player, stream)
    local origin = ctx:get(player, component.POSITION)
    local radius = vision.radius(ctx, player)

    local tries = math.max(1,
        random2(ctx, stream, random2(ctx, stream, 14)))
    local placed = 0

    for _ = 1, tries do
        local x, y = near_floor(ctx, origin, radius,
            stream, false)

        if not x then
            x, y = near_floor(ctx, origin, radius,
                stream, true)
        end

        if x then
            ctx:set_cell(origin.level_id, x, y,
                terrain.DNGN_ALTAR_XOM)
            placed = placed + 1
        end
    end

    return placed
end

-- Butterflies are real friendly summons with Xom as their source. Their
-- ordinary summon component owns expiry, allegiance, and save/restore.
local function summon_butterflies(ctx, player, stream)
    local count = 10 + ctx:random(stream, 11)
    local created = 0

    for _ = 1, count do
        local butterfly = summon.spawn(ctx, player, gods.XOM,
            monsters.MONS_BUTTERFLY, 3, nil, {
                attitude = attitudes.FRIENDLY,
                source_category = categories.GODS,
                stream = stream,
                silent_failure = true,
            })

        if butterfly then
            created = created + 1
        end
    end

    return created
end

-- Each candidate is rechecked against the live grid. Open and closed
-- gates switch features, while blue or dry fountains may become blood.
local function change_candidates(ctx, player, candidates, stream)
    local origin = ctx:get(player, component.POSITION)
    local changed = 0
    local moved_doors = false
    local blood = 0

    for _, point in ipairs(candidates) do
        local feature = ctx:cell(origin.level_id, point.x, point.y)
        local replacement = open_to_closed[feature] or
            closed_to_open[feature]

        if replacement then
            ctx:set_cell(origin.level_id, point.x, point.y,
                replacement)
            moved_doors = true
            changed = changed + 1
        elseif (feature == terrain.DNGN_FOUNTAIN_BLUE or
            feature == terrain.DNGN_FOUNTAIN_DRY) and
            (blood == 0 or ctx:random(stream, 3) >= blood) then
            ctx:set_cell(origin.level_id, point.x, point.y,
                terrain.DNGN_FOUNTAIN_BLOOD)
            blood = blood + 1
            changed = changed + 1
        end
    end

    if moved_doors then
        noise.emit(ctx, origin, 10, player)
    end

    return changed
end

-- Visible scenery wins over the rare fallback. A failed fallback returns
-- zero rather than claiming that Xom changed something the player can see.
function effect.apply(ctx, player, event_id, _severity, request)
    if event_id ~= events.GOOD_SCENERY then
        error("scenery effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local candidates = effect.candidates(ctx, player)
    local changed

    if #candidates > 0 then
        changed = change_candidates(ctx, player, candidates, stream)
    elseif ctx:random(stream, 2) == 0 then
        changed = place_altars(ctx, player, stream)
    else
        changed = summon_butterflies(ctx, player, stream)
    end

    if changed > 0 then
        ctx:emit(channels.RELIGION,
            "Xom rearranges the scenery!")
    end

    return changed
end

return effect
