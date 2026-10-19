local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local targets = require("policy.ai.targets")
local summons = require("policy.magic.effects.summons.common")
local invisibility = require("policy.potions.invisibility")

local constructs = require("constants.monster_construct_components")
local habitat = require("policy.combat.monster_habitat")

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

-- Emerged heads own their anchor after the source removes the portal marker.
-- Attached tentacles instead anchor to their living parent.
local function gateway(ctx, head)
    local attached = ctx:get(head, constructs.TENTACLE)

    if attached then
        local position = ctx:get(attached.parent, component.POSITION)
        local health = ctx:get(attached.parent, component.HEALTH)

        if position and health and health.current > 0 then
            return attached.parent, position
        end

        return nil, nil
    end

    local portal = ctx:get(head, constructs.PORTAL)
    local position = ctx:get(head, component.POSITION)

    if portal and position then
        return head, {
            level_id = position.level_id,
            x = portal.anchor_x,
            y = portal.anchor_y,
        }
    end

    return nil, nil
end

-- Source mon-tentacle.cc picks an unoccupied habitable neighbor of the
-- severed BASE_POSITION each time the head acts. Keep that moving anchor on
-- the head, since the marker must retain the portal's original location.
local function drift_anchor(ctx, head, base)
    local portal = ctx:get(head, constructs.PORTAL)

    if not portal or not portal.severed then
        return base
    end

    for _, offset in ipairs(offsets) do
        local x = base.x + offset[1]
        local y = base.y + offset[2]

        if not ctx:actor_at(base.level_id, x, y) and
            habitat.at(ctx, head, base.level_id, x, y) then
            portal.anchor_x = x
            portal.anchor_y = y
            ctx:set(head, constructs.PORTAL, portal)

            return {
                level_id = base.level_id,
                x = x,
                y = y,
            }
        end
    end

    return base
end

-- Unlike ordinary nearest-enemy AI, an attached gateway head can pursue
-- only foes visible to both the head and the portal's anchor. This mirrors
-- the two sight tests in mon-tentacle.cc:_collect_foe_positions.
local function gateway_target(ctx, head, position, base)
    local nearest
    local closest = 8

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local foe = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)
        local reach = distance(position, foe)

        if health.current > 0 and foe.level_id == position.level_id and
            reach < closest and targets.enemy(ctx, head, entity) and
            (entity ~= ctx:player() or
                invisibility.visible_to(ctx, entity, head)) and
            ctx:visible(position.level_id, position.x, position.y,
                7, foe.x, foe.y) and
            ctx:visible_no_trans(base.level_id, base.x, base.y,
                7, foe.x, foe.y) then
            nearest = entity
            closest = reach
        end
    end

    return nearest
end

-- Source: mon-tentacle.cc:move_solo_tentacle uses a five-cell connection
-- limit for eldritch tentacles. Search traversable connector cells first,
-- allowing this head's existing segments to occupy the old chain.
local function path(ctx, head, base, goal)
    local limit = ctx:has(head, constructs.TENTACLE) and 12 or 5
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

        if steps[cell_key] < limit then
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
                    habitat.at(ctx, head, base.level_id, x, y) then
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

-- The disconnected head has no foe search in the source. Retract one step
-- along its current chain, vacating an old connector before Go grid movement.
local function severed_retraction(ctx, head, base, position)
    local connection = path(ctx, head, base, position)
    local next_cell = connection and connection[#connection - 1]

    if not next_cell or
        distance(next_cell, base) >= distance(position, base) then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local occupant = ctx:actor_at(position.level_id,
        next_cell.x, next_cell.y)
    local segment = occupant and ctx:get(occupant,
        component.SUMMON_SEGMENT)

    -- C++ purges its old connector chain before moving the head. The Go
    -- grid needs the destination vacated explicitly first.
    if segment and segment.head == head then
        summons.expire(ctx, occupant)
        occupant = nil
    end

    if occupant then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    return {
        kind = intent_ids.MONSTER_MOVE,
        dx = next_cell.x - position.x,
        dy = next_cell.y - position.y,
    }
end

-- Choose melee at range one; otherwise move closer only along a legal connected chain.
function tentacle.act(ctx, head, position)
    local marker, base = gateway(ctx, head)

    if not marker then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local attached = ctx:has(head, constructs.TENTACLE)
    base = drift_anchor(ctx, head, base)
    local limit = attached and 12 or 5
    local target

    if attached then
        target = targets.nearest(ctx, head, base, 7)
    else
        local portal = ctx:get(head, constructs.PORTAL)

        if not portal or not portal.severed then
            target = gateway_target(ctx, head, position, base)
        end
    end

    local grip = ctx:get(ctx:player(), component.CONSTRICTION)
    local pulling = attached and grip and grip.by == head

    -- The source reconnects after every anchor shift. If the new base
    -- cannot reach the head within the tether, that head self-destructs.
    if not attached and not path(ctx, head, base, position) then
        summons.expire(ctx, head)

        return { kind = intent_ids.MONSTER_WAIT }
    end

    if attached and (not target or pulling) then
        local connection = path(ctx, head, base, position)

        if not target and distance(position, base) == 1 then
            summons.expire(ctx, head)

            return { kind = intent_ids.MONSTER_WAIT }
        end

        local next_cell = connection and connection[#connection - 1]

        if next_cell and distance(next_cell, base) > 0 then
            local occupant = ctx:actor_at(position.level_id,
                next_cell.x, next_cell.y)
            local segment = occupant and ctx:get(occupant, component.SUMMON_SEGMENT)

            if segment and segment.head == head then
                summons.expire(ctx, occupant)
                occupant = nil
            end

            if not occupant then
                return {
                    kind = intent_ids.MONSTER_MOVE,
                    dx = next_cell.x - position.x,
                    dy = next_cell.y - position.y,
                }
            end
        end

        return { kind = intent_ids.MONSTER_WAIT }
    elseif not target then
        local portal = ctx:get(head, constructs.PORTAL)

        if portal and portal.severed then
            return severed_retraction(ctx, head, base, position)
        end

        return { kind = intent_ids.MONSTER_WAIT }
    end

    local destination = ctx:get(target, component.POSITION)
    local range = distance(position, destination)

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

        if distance(next_position, base) <= limit and
            habitat.at(ctx, head, position.level_id, x, y) and
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

    -- mon-tentacle.cc:_purge_connectors transfers the least surviving
    -- connector HP to the head before rebuilding the chain.
    for _, segment in ipairs(ctx:query({ component.SUMMON_SEGMENT })) do
        local link = ctx:get(segment, component.SUMMON_SEGMENT)
        local health = ctx:get(segment, component.HEALTH)

        if link.head == head and health then
            head_health.current = math.min(head_health.current, health.current)
        end
    end

    ctx:set(head, component.HEALTH, head_health)

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
                ctx:set(actor, component.HEALTH, {
                    current = head_health.current,
                    max = head_health.max,
                })
                wanted[position_key] = nil
            else
                summons.expire(ctx, actor)
            end
        end
    end

    local head_state = ctx:get(head, component.SUMMON)
    local actor = ctx:get(head, component.ACTOR)
    local segment_kinds = {
        [monsters.MONS_KRAKEN_TENTACLE] = monsters.MONS_KRAKEN_TENTACLE_SEGMENT,
        [monsters.MONS_STARSPAWN_TENTACLE] = monsters.MONS_STARSPAWN_TENTACLE_SEGMENT,
    }
    local segment_kind = segment_kinds[actor.kind_id] or
        monsters.MONS_ELDRITCH_TENTACLE_SEGMENT
    for index = 2, #connection - 1 do
        local cell = connection[index]
        local position_key = key(cell.x, cell.y)

        if wanted[position_key] then
            local segment = summons.spawn(ctx, head_state.owner,
                head_state.source_id, segment_kind,
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
                    attitude = head_state.attitude,
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
            not ctx:has(segment.gateway, component.SUMMON_GATEWAY) and
                not ctx:has(segment.head, constructs.TENTACLE) and
                not ctx:has(segment.head, constructs.PORTAL) then
            summons.expire(ctx, actor)
        end
    end
end

return tentacle
