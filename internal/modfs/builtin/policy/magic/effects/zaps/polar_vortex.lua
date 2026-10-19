local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local terrain = require("constants.terrain")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local direct = require("policy.combat.monster_direct")
local habitat = require("policy.combat.monster_habitat")
local registry = require("policy.magic.effects.registry")
local resistance_ids = require("constants.resistance_ids")
local forms = require("policy.magic.effects.forms.player")

local vortex = {}

local radius = 5
local directions = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 },               { 1, 0 },
    { -1, 1 },  { 0, 1 },  { 1, 1 },
}

local trees = {
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
}

-- Coordinate keys keep the wind graph and destination reservations independent of table identity.
local function key(x, y)
    return x .. ":" .. y
end

-- Vortex rings use Chebyshev distance so diagonals belong to the same radius.
local function distance(x, y, origin)
    return math.max(math.abs(x - origin.x), math.abs(y - origin.y))
end

-- Spell-stream remainder roll keeps fractional wind damage unbiased over tick lengths.
local function random_round(ctx, numerator, denominator)
    if denominator <= 0 then
        return 0
    end

    local result = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        result = result + 1
    end

    return result
end

-- Integrate the ramped early-age curve before differencing elapsed action time.
local function integrated_damage(age)
    if age <= 0 then
        return 0
    end

    if age < 10 then
        return math.floor(age * age / 2)
    end

    return age * 10 - 50
end

-- Integrating the age curve preserves the same damage across short and long elapsed ticks.
local function ring_duration(age, elapsed, ring)
    local effective = age - math.floor(ring * ring * 7 / 5)

    return integrated_damage(effective + elapsed) -
        integrated_damage(effective)
end

-- Build wind reach around walls before rotating actors and applying cold damage.
local function wind_cells(ctx, origin)
    local level = origin.level_id
    local depth = {}
    local cuts = {}
    local cells = {}

    -- DFS low links mark cut cells where wind would be disconnected beyond that point.
    local function visit(x, y, current_depth, parent)
        local id = key(x, y)
        local low = current_depth
        local greatest_child_low = -1

        depth[id] = current_depth
        cells[id] = { x = x, y = y }

        for _, direction in ipairs(directions) do
            local next_x = x + direction[1]
            local next_y = y + direction[2]
            local next_id = key(next_x, next_y)

            if distance(next_x, next_y, origin) <= radius and
                ctx:walkable(level, next_x, next_y) then
                if depth[next_id] == nil then
                    local child_low = visit(next_x, next_y,
                        current_depth + 1, id)

                    low = math.min(low, child_low)
                    greatest_child_low = math.max(greatest_child_low,
                        child_low)
                elseif next_id ~= parent then
                    low = math.min(low, depth[next_id])
                end
            end
        end

        cuts[id] = greatest_child_low >= current_depth

        return low
    end

    visit(origin.x, origin.y, 0, nil)
    cuts[key(origin.x, origin.y)] = false

    local winds = {}

    -- Stop propagation at cut cells while retaining the cell itself as exposed to wind.
    local function pass(x, y)
        local id = key(x, y)

        if winds[id] or not cells[id] then
            return
        end

        winds[id] = true

        if cuts[id] then
            return
        end

        for _, direction in ipairs(directions) do
            pass(x + direction[1], y + direction[2])
        end
    end

    pass(origin.x, origin.y)

    return winds
end

-- A square-ring angular coordinate avoids trigonometric drift when ranking rotations.
local function angle(x, y)
    if math.abs(x) > math.abs(y) then
        return x > 0 and y / x or 4 + y / x
    end

    return y > 0 and 2 - x / y or -2 - x / y
end

-- Prefer the same ring and the expected angular shift when choosing a destination.
local function rotation_score(origin, from, to, duration)
    local ring = distance(from.x, from.y, origin)
    local dest_ring = distance(to.x, to.y, origin)
    local wanted = angle(from.x - origin.x, from.y - origin.y) -
        duration * 0.01 * 4 / 3
    local dest_angle = angle(to.x - origin.x, to.y - origin.y)
    local delta = math.abs(dest_angle - wanted)

    return math.abs(dest_ring - ring) +
        math.min(delta, math.abs(delta - 8)) * 3 / 2
end

-- Immobile species are damaged by wind but cannot be rotated around the caster.
local function stationary(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == "M_STATIONARY" then
            return true
        end
    end

    return false
end

-- Rooted monsters remain in place while still taking cold damage. A
-- hostile monster storm can rotate the player; source movement is not
-- limited to monster victims.
local function can_move(ctx, actor)
    if ctx:has(actor, component.PLAYER) then
        return true
    end

    local monster = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", monster.kind_id)

    return not stationary(definition) and
        not ctx:has(actor, component.MONSTER_VILE_CLUTCH) and
        not ctx:has(actor, component.GRASPING_ROOTS)
end

-- Source vortex resistance belongs to an actor with its own storm or a
-- monster catalog resistance. Sharing this check keeps AI and pulses in
-- agreement, including a player who is already controlling the winds.
function vortex.immune(ctx, actor)
    if ctx:has(actor, zap_ids.component.POLAR_VORTEX) then
        return true
    end

    if ctx:has(actor, component.PLAYER) then
        return false
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", state.kind_id)

    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == resistance_ids.VORTEX and entry.level > 0 then
            return true
        end
    end

    return false
end

-- Twelve spell draws feed resistance and proportional armour for each
-- exposed actor. Health ownership keeps the caster as the damage source.
local function cold_damage(ctx, caster, actor, ring_power)
    local rolled = 0

    for _ = 1, 12 do
        rolled = rolled + 1 + ctx:random("spell", ring_power)
    end

    local raw = random_round(ctx, rolled, 15)
    local maximum = math.max(1, math.floor(12 * ring_power / 15))

    if ctx:has(actor, component.PLAYER) then
        local adjusted = damage.player_elemental(ctx, actor, raw,
            "MR_RES_COLD")
        local amount = damage.player_proportional_armour(ctx,
            actor, adjusted, maximum)

        direct.damage(ctx, caster, actor, amount)
        return
    end

    local adjusted = damage.monster_elemental(ctx, actor, raw,
        "MR_RES_COLD")
    local amount = damage.monster_proportional_armour(ctx,
        actor, adjusted, maximum)

    direct.damage(ctx, caster, actor, amount)
end

-- A destination may hold another moving victim because the final move is simultaneous.
local function available_cell(ctx, level, actor, x, y, moving)
    local permitted = ctx:has(actor, component.PLAYER) and
        ctx:walkable(level, x, y) or
        habitat.at(ctx, actor, level, x, y)

    if not permitted then
        return false
    end

    local occupant = ctx:actor_at(level, x, y)

    return occupant == nil or moving[occupant]
end

-- Each exposed victim receives short temporary flight before wind moves
-- them. This is actor state so another action can age it after the storm.
local function grant_flight(ctx, actor, duration)
    local state = ctx:get(actor, component.ZAP_FLIGHT)

    if state then
        state.remaining_aut = math.max(state.remaining_aut,
            duration)
        ctx:set(actor, component.ZAP_FLIGHT, state)
    else
        ctx:add(actor, component.ZAP_FLIGHT, {
            remaining_aut = duration,
        })
    end
end

-- Reserve each chosen cell once, then move all victims together to avoid order-dependent collisions.
local function rotate(ctx, origin, candidates, cells)
    local moving = {}

    for _, entry in ipairs(candidates) do
        moving[entry.actor] = true
    end

    local moves = {}
    local used = {}

    for _, entry in ipairs(candidates) do
        local best = entry.position
        local best_score = math.huge

        for _, cell in ipairs(cells) do
            local id = key(cell.x, cell.y)

            if not used[id] and available_cell(ctx,
                origin.level_id, entry.actor, cell.x, cell.y, moving) then
                local score = rotation_score(origin,
                    entry.position, cell, entry.ring_duration)

                if score < best_score then
                    best = cell
                    best_score = score
                end
            end
        end

        used[key(best.x, best.y)] = true
        moves[#moves + 1] = {
            actor = entry.actor,
            level_id = origin.level_id,
            x = best.x,
            y = best.y,
        }
    end

    if #moves > 0 then
        ctx:move_actors(moves)
    end
end

-- Both caster types keep the same storm shape and flight timer. Player and
-- monster cast entry points choose their own power and messages.
function vortex.start(ctx, actor, power)
    local value = {
        remaining_aut = 60,
        started_aut = ctx:aut(),
        power = power,
    }

    if ctx:has(actor, zap_ids.component.POLAR_VORTEX) then
        ctx:set(actor, zap_ids.component.POLAR_VORTEX, value)
    else
        ctx:add(actor, zap_ids.component.POLAR_VORTEX, value)
    end

    grant_flight(ctx, actor, 60)
end

-- The player spell registry calls this contract after mana and failure
-- handling; only the announcement is player-specific.
function vortex.resolve(ctx, player, _, _, power)
    vortex.start(ctx, player, power)

    ctx:emit("spell", "A great freezing vortex appears around you!")
end

-- Count the whole square ring, including wall-shadowed cells, because
-- source power weakens in proportion to how much wind can reach the ring.
local function cells_in_ring(ctx, origin, winds, ring)
    local cells = {}
    local open = 0

    for dy = -ring, ring do
        for dx = -ring, ring do
            if math.max(math.abs(dx), math.abs(dy)) == ring then
                local x = origin.x + dx
                local y = origin.y + dy

                if ctx:cell(origin.level_id, x, y) then
                    cells[#cells + 1] = { x = x, y = y }

                    if winds[key(x, y)] then
                        open = open + 1
                    end
                end
            end
        end
    end

    return cells, open
end

-- Cold and flight require vulnerability. Displacement is independent of
-- vortex resistance; source still rotates a cold-immune wind victim.
local function expose_victim(ctx, caster, victim, cell,
    duration, power, candidates)
    local forbidden = ctx:has(victim, component.PLAYER) and
        forms.modifiers(ctx, victim).flight == "forbid"

    if forbidden then
        return false
    end

    if not vortex.immune(ctx, victim) then
        if can_move(ctx, victim) then
            grant_flight(ctx, victim, 20)
        end

        cold_damage(ctx, caster, victim, power)
    end

    local health = ctx:get(victim, component.HEALTH)

    if health and health.current > 0 and can_move(ctx, victim) then
        candidates[#candidates + 1] = {
            actor = victim,
            position = cell,
            ring_duration = duration,
        }
    end

    return true
end

-- Tree falls precede actor effects in the source ring loop. A player form
-- that forbids flight skips the whole cell, including movement reservation.
local function affect_cell(ctx, caster, origin, winds, cell,
    duration, power, candidates, available)
    local feature = ctx:cell(origin.level_id, cell.x, cell.y)

    if trees[feature] and ctx:random("spell", 2000) < duration then
        ctx:set_cell(origin.level_id, cell.x, cell.y,
            terrain.DNGN_FLOOR)
        ctx:emit("spell", "A tree falls to the furious winds!")
    end

    if not winds[key(cell.x, cell.y)] then
        return
    end

    local victim = ctx:actor_at(origin.level_id, cell.x, cell.y)

    if victim and not expose_victim(ctx, caster, victim, cell,
        duration, power, candidates) then
        return
    end

    if ctx:walkable(origin.level_id, cell.x, cell.y) then
        available[#available + 1] = cell
    end
end

-- Integrate one action's wind exposure across expanding rings, then move
-- all chosen actors together so no earlier move changes a later hit.
local function pulse(ctx, caster, state, exposure)
    local origin = ctx:get(caster, component.POSITION)
    local winds = wind_cells(ctx, origin)
    local age = math.max(0, ctx:aut() - state.started_aut)
    local open = 0
    local all = 0
    local candidates = {}
    local available = {}

    for ring = 1, radius do
        local cells, ring_open = cells_in_ring(ctx,
            origin, winds, ring)

        open = open + ring_open
        all = all + #cells

        local duration = ring_duration(age, exposure, ring)
        local power = random_round(ctx,
            state.power * open * duration, all * 100)

        if power <= 0 then
            break
        end

        for _, cell in ipairs(cells) do
            affect_cell(ctx, caster, origin, winds, cell,
                duration, power, candidates, available)
        end
    end

    rotate(ctx, origin, candidates, available)
end

-- Saved cast power and elapsed age drive wind-ring effects. Monster speed
-- changes pulse exposure, but the enchantment timer follows baseline aut.
-- Temporary flight ages in its own actor-wide system after the action.
function vortex.tick(ctx, actor, aut, pulse_aut)
    local state = ctx:get(actor, zap_ids.component.POLAR_VORTEX)

    if not state then
        return
    end

    pulse(ctx, actor, state, pulse_aut or aut)
    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut <= 0 then
        ctx:remove(actor, zap_ids.component.POLAR_VORTEX)
        if ctx:has(actor, component.PLAYER) then
            ctx:emit("duration", "The freezing vortex dissipates.")
        end

        return true
    else
        ctx:set(actor, zap_ids.component.POLAR_VORTEX, state)
    end
end

-- The player tick remains after its cast. Monster enchantment ticks are
-- scheduled before its decision in a separate monster-only system.
function vortex.tick_player(ctx, actor, aut)
    if ctx:has(actor, component.PLAYER) then
        vortex.tick(ctx, actor, aut)
    end
end

registry.add(spells.SPELL_POLAR_VORTEX, vortex)

-- Theory of operation: Player vortex time advances after spell attacks but before movement.
-- This preserves cast-turn timing.
register.system({
    id = "zap.polar_vortex.tick",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = vortex.tick_player,
})

return vortex
