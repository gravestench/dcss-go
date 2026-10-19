local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local targets = require("policy.ai.targets")
local summons = require("policy.magic.effects.summons.common")

local tentacle = {}

local offsets = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 }, { 1, 0 },
    { -1, 1 }, { 0, 1 }, { 1, 1 },
}

-- Coordinate keys let the connector search reuse or retire existing segment cells.
local function key(x, y)
    return x .. ":" .. y
end

-- The tentacle uses Chebyshev reach for its five-cell tether and target approach.
local function distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

-- Sorting candidate steps by remaining target distance makes movement deterministic.
local function closer_target(left, right)
    return left.distance < right.distance
end

-- Only an active gateway whose saved tentacle ID matches can anchor this head.
local function gateway(ctx, head)
    for _, marker in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local state = ctx:get(marker, component.SUMMON_GATEWAY)

        if state.phase == 1 and state.tentacle_id == ctx:id(head) then
            return marker, state
        end
    end

    return nil, nil
end

-- Source: mon-tentacle.cc:move_solo_tentacle uses a five-cell connection
-- limit for eldritch tentacles. Search traversable connector cells first,
-- allowing this head's existing segments to occupy the old chain.
local function path(ctx, head, base, goal)
    local start = { x = base.x, y = base.y }
    local queue = { start }
    local visited = { [key(start.x, start.y)] = true }
    local previous = {}
    local steps = { [key(start.x, start.y)] = 0 }
    local front = 1

    while front <= #queue do
        local cell = queue[front]
        local cell_key = key(cell.x, cell.y)
        front = front + 1

        if cell.x == goal.x and cell.y == goal.y then
            local result = { cell }

            while previous[cell_key] do
                cell = previous[cell_key]
                cell_key = key(cell.x, cell.y)
                table.insert(result, 1, cell)
            end

            return result
        end

        if steps[cell_key] < 5 then
            for _, offset in ipairs(offsets) do
                local x = cell.x + offset[1]
                local y = cell.y + offset[2]
                local next_key = key(x, y)
                local occupant = ctx:actor_at(base.level_id, x, y)
                local segment = occupant and ctx:get(occupant,
                    component.SUMMON_SEGMENT)
                local open = not occupant or occupant == head or
                    (segment and segment.head == head)

                if not visited[next_key] and open and
                    ctx:walkable(base.level_id, x, y) then
                    visited[next_key] = true
                    previous[next_key] = cell
                    steps[next_key] = steps[cell_key] + 1
                    queue[#queue + 1] = { x = x, y = y }
                end
            end
        end
    end

    return nil
end

-- Choose melee at range one; otherwise move closer only along a legal connected chain.
function tentacle.act(ctx, head, position)
    local marker, base = gateway(ctx, head)

    if not marker then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local target, range = targets.nearest(ctx, head, position, 7)

    if not target then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local destination = ctx:get(target, component.POSITION)

    if range == 1 then
        return {
            kind = intent_ids.MONSTER_MELEE,
            dx = destination.x - position.x,
            dy = destination.y - position.y,
        }
    end

    local candidates = {}

    for _, offset in ipairs(offsets) do
        local x = position.x + offset[1]
        local y = position.y + offset[2]
        local next_position = { x = x, y = y }

        if distance(next_position, base) <= 5 and
            ctx:walkable(position.level_id, x, y) and
            not ctx:actor_at(position.level_id, x, y) and
            path(ctx, head, base, next_position) then
            candidates[#candidates + 1] = {
                dx = offset[1],
                dy = offset[2],
                distance = distance(next_position, destination),
            }
        end
    end

    table.sort(candidates, closer_target)

    if candidates[1] and candidates[1].distance < range then
        return {
            kind = intent_ids.MONSTER_MOVE,
            dx = candidates[1].dx,
            dy = candidates[1].dy,
        }
    end

    return { kind = intent_ids.MONSTER_WAIT }
end

-- Rebuild intermediate segments along the current path, retaining matching entities when possible.
function tentacle.refresh(ctx, head)
    local marker, base = gateway(ctx, head)
    local position = ctx:get(head, component.POSITION)
    local head_health = ctx:get(head, component.HEALTH)

    if not marker or not position or not head_health or
        head_health.current <= 0 then
        return
    end

    local connection = path(ctx, head, base, position)

    if not connection then
        return
    end

    local wanted = {}

    for index = 2, #connection - 1 do
        local cell = connection[index]
        wanted[key(cell.x, cell.y)] = index - 1
    end

    for _, actor in ipairs(ctx:query({ component.SUMMON_SEGMENT })) do
        local segment = ctx:get(actor, component.SUMMON_SEGMENT)

        if segment.head == head then
            local cell = ctx:get(actor, component.POSITION)
            local position_key = cell and key(cell.x, cell.y)

            if position_key and wanted[position_key] then
                segment.index = wanted[position_key]
                ctx:set(actor, component.SUMMON_SEGMENT, segment)
                wanted[position_key] = nil
            else
                summons.expire(ctx, actor)
            end
        end
    end

    local head_state = ctx:get(head, component.SUMMON)
    for index = 2, #connection - 1 do
        local cell = connection[index]
        local position_key = key(cell.x, cell.y)

        if wanted[position_key] then
            local segment = summons.spawn(ctx, head_state.owner,
                head_state.source_id, monsters.MONS_ELDRITCH_TENTACLE_SEGMENT,
                0, 6, {
                    anchor = {
                        level_id = base.level_id,
                        x = base.x,
                        y = base.y,
                    },
                    exact = { x = cell.x, y = cell.y },
                    hp = head_health.current,
                    expires_aut = head_state.expires_aut,
                    segment = true,
                    source_category = head_state.source_category,
                    hostile = head_state.hostile,
                })

            if segment then
                local health = ctx:get(segment, component.HEALTH)
                health.max = head_health.max
                ctx:set(segment, component.HEALTH, health)
                ctx:add(segment, component.SUMMON_SEGMENT, {
                    head = head,
                    gateway = marker,
                    index = index - 1,
                })
            end
        end
    end
end

-- A killed segment kills its head so a severed chain cannot keep acting.
function tentacle.segment_death(ctx, actor)
    local segment = ctx:get(actor, component.SUMMON_SEGMENT)
    local health = ctx:get(actor, component.HEALTH)

    if segment and health and health.current <= 0 then
        local head_health = ctx:get(segment.head, component.HEALTH)

        if head_health and head_health.current > 0 then
            head_health.current = 0
            ctx:set(segment.head, component.HEALTH, head_health)
        end
    end
end

-- Example: A tentacle segment whose head died expires during orphan cleanup.
-- Expire segments when the head or gateway vanishes after a prior lifecycle event.
function tentacle.clean_orphans(ctx)
    for _, actor in ipairs(ctx:query({ component.SUMMON_SEGMENT })) do
        local segment = ctx:get(actor, component.SUMMON_SEGMENT)
        local health = ctx:get(segment.head, component.HEALTH)

        if not health or health.current <= 0 or
            not ctx:has(segment.gateway, component.SUMMON_GATEWAY) then
            summons.expire(ctx, actor)
        end
    end
end

return tentacle
