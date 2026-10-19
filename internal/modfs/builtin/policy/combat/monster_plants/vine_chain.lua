-- Theory of operation: a snaplasher head may reach eight connected cells
-- from its saved tree anchor. The path is rebuilt from terrain and actor
-- occupancy on each decision. Intermediate cells hold real summon segment
-- actors, so other combatants see the same obstruction after save/restore.
-- Source: mon-tentacle.cc:_move_tentacle and _try_tentacle_connect.
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local intent = require("constants.intent")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")

local chain = {}
local MAX_REACH = 8

local offsets = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 }, { 1, 0 },
    { -1, 1 }, { 0, 1 }, { 1, 1 },
}

-- Coordinate keys represent level-local cells only; every path is
-- constructed from one head and therefore one known level.
local function key(x, y)
    return x .. ":" .. y
end

-- Both target reach and source tether length use square-grid distance.
local function distance(a, b)
    return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

-- Traverse only open cells or existing connectors from this head. A dead
-- chain is never accepted as a path around an unrelated actor.
local function open_path_cell(ctx, head, level_id, x, y)
    if not habitat.kind_at(ctx, monsters.MONS_SNAPLASHER_VINE,
        level_id, x, y) then
        return false
    end

    local occupant = ctx:actor_at(level_id, x, y)

    if not occupant or occupant == head then
        return true
    end

    local segment = ctx:get(occupant, component.MONSTER_VINE_SEGMENT)

    return segment and segment.head == head
end

-- Breadth-first search gives the shortest connected chain and caps it
-- at the source's eight-cell vine reach.
function chain.path(ctx, head, goal)
    local vine = ctx:get(head, component.MONSTER_VINE)
    local position = ctx:get(head, component.POSITION)

    if not vine or not position then
        return nil
    end

    local origin = {
        x = vine.anchor_x,
        y = vine.anchor_y,
    }
    local queue = { origin }
    local previous = {}
    local steps = { [key(origin.x, origin.y)] = 0 }
    local first = 1

    while first <= #queue do
        local cell = queue[first]
        local current_key = key(cell.x, cell.y)
        first = first + 1

        if cell.x == goal.x and cell.y == goal.y then
            local path = { cell }

            while previous[current_key] do
                cell = previous[current_key]
                current_key = key(cell.x, cell.y)
                table.insert(path, 1, cell)
            end

            return path
        end

        if steps[current_key] < MAX_REACH then
            for _, offset in ipairs(offsets) do
                local x = cell.x + offset[1]
                local y = cell.y + offset[2]
                local next_key = key(x, y)

                if not steps[next_key] and
                    open_path_cell(ctx, head, position.level_id, x, y) then
                    steps[next_key] = steps[current_key] + 1
                    previous[next_key] = cell
                    queue[#queue + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    return nil
end

-- A constricting vine retracts toward its tree before trying to lash its
-- held victim again. Save the vacated head cell for post-movement dragging.
local function retract(ctx, head, state, position)
    local anchor = {
        x = state.anchor_x,
        y = state.anchor_y,
    }
    local current = distance(position, anchor)

    for _, offset in ipairs(offsets) do
        local x = position.x + offset[1]
        local y = position.y + offset[2]
        local candidate = {
            x = x,
            y = y,
        }

        if distance(candidate, anchor) < current and
            not ctx:actor_at(position.level_id, x, y) and
            chain.path(ctx, head, candidate) then
            state.pull_x = position.x
            state.pull_y = position.y
            state.pull_pending = true
            ctx:set(head, component.MONSTER_VINE, state)

            return {
                kind = intent.MONSTER_MOVE,
                dx = offset[1],
                dy = offset[2],
            }
        end
    end

    return nil
end

-- A vine attacks an adjacent foe; otherwise it takes a step that shortens
-- the gap without severing the anchored path. It never wanders away.
function chain.act(ctx, head)
    local state = ctx:get(head, component.MONSTER_VINE)
    local position = ctx:get(head, component.POSITION)
    local victim = state and ctx:get(state.target, component.POSITION)
    local health = state and ctx:get(state.target, component.HEALTH)

    if not position or not victim or not health or health.current <= 0 or
        victim.level_id ~= position.level_id or
        not targets.enemy(ctx, head, state.target) then
        return { kind = intent.MONSTER_WAIT }
    end

    local current = distance(position, victim)

    if current == 1 then
        local hold = ctx:get(state.target,
            component.MONSTER_VINE_GRIP)

        if hold and hold.by == head then
            local step = retract(ctx, head, state, position)

            if step then
                return step
            end
        end

        return {
            kind = intent.MONSTER_MELEE,
            dx = victim.x - position.x,
            dy = victim.y - position.y,
        }
    end

    local best
    local closest = current

    for _, offset in ipairs(offsets) do
        local x = position.x + offset[1]
        local y = position.y + offset[2]
        local candidate = {
            x = x,
            y = y,
        }
        local remaining = distance(candidate, victim)

        if remaining < closest and
            not ctx:actor_at(position.level_id, x, y) and
            chain.path(ctx, head, candidate) then
            best = offset
            closest = remaining
        end
    end

    if best then
        return {
            kind = intent.MONSTER_MOVE,
            dx = best[1],
            dy = best[2],
        }
    end

    return { kind = intent.MONSTER_WAIT }
end

-- After a successful retraction, the victim follows into the head's old
-- cell. A blocked or cancelled move clears the marker without teleporting.
local function drag(ctx, head, position)
    local state = ctx:get(head, component.MONSTER_VINE)

    if not state.pull_pending then
        return
    end

    state.pull_pending = false
    ctx:set(head, component.MONSTER_VINE, state)

    if position.x == state.pull_x and position.y == state.pull_y then
        return
    end

    local victim = state.target
    local hold = ctx:get(victim, component.MONSTER_VINE_GRIP)
    local target_position = ctx:get(victim, component.POSITION)

    if not hold or hold.by ~= head or not target_position or
        target_position.level_id ~= position.level_id or
        ctx:actor_at(position.level_id,
            state.pull_x, state.pull_y) or
        not ctx:walkable(position.level_id,
            state.pull_x, state.pull_y) then
        return
    end

    ctx:move_actor(victim, position.level_id,
        state.pull_x, state.pull_y)
    ctx:emit("combat", "The vine drags its foe backwards!")
end

-- Reuse segments in cells still on the shortest path. Retire old pieces
-- first so replacement placement never collides with a stale connector.
function chain.refresh(ctx, head)
    local position = ctx:get(head, component.POSITION)
    local health = ctx:get(head, component.HEALTH)

    if not position or not health or health.current <= 0 then
        return
    end

    drag(ctx, head, position)

    local path = chain.path(ctx, head, position)

    if not path then
        return
    end

    local wanted = {}

    for index = 2, #path - 1 do
        local cell = path[index]

        wanted[key(cell.x, cell.y)] = index - 1
    end

    for _, entity in ipairs(ctx:query({ component.MONSTER_VINE_SEGMENT })) do
        local segment = ctx:get(entity, component.MONSTER_VINE_SEGMENT)

        if segment.head == head then
            local cell = ctx:get(entity, component.POSITION)
            local position_key = cell and key(cell.x, cell.y)

            if position_key and wanted[position_key] then
                segment.index = wanted[position_key]
                ctx:set(entity, component.MONSTER_VINE_SEGMENT, segment)
                wanted[position_key] = nil
            else
                summons.expire(ctx, entity)
            end
        end
    end

    local summon = ctx:get(head, component.SUMMON)
    for index = 2, #path - 1 do
        local cell = path[index]

        if wanted[key(cell.x, cell.y)] then
            local entity = summons.spawn(ctx, summon.owner,
                spells.SPELL_AWAKEN_VINES,
                monsters.MONS_SNAPLASHER_VINE_SEGMENT,
                0, nil, {
                    anchor = position,
                    exact = {
                        x = cell.x,
                        y = cell.y,
                    },
                    hp = health.current,
                    expires_aut = summon.expires_aut,
                    passive = true,
                    segment = true,
                    attitude = summon.attitude,
                })

            if entity then
                ctx:add(entity, component.MONSTER_VINE_SEGMENT, {
                    head = head,
                    index = index - 1,
                })
            end
        end
    end
end

-- Remove orphan connectors if a head was killed or expired by another
-- system; the caster's ordinary summon relation handles the heads.
function chain.clean_orphans(ctx)
    for _, entity in ipairs(ctx:query({ component.MONSTER_VINE_SEGMENT })) do
        local segment = ctx:get(entity, component.MONSTER_VINE_SEGMENT)
        local health = ctx:get(segment.head, component.HEALTH)

        if not ctx:has(segment.head, component.MONSTER_VINE) or
            not health or health.current <= 0 then
            summons.expire(ctx, entity)
        end
    end
end

return chain
