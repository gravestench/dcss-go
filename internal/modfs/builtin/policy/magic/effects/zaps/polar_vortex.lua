local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local terrain = require("constants.terrain")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local habitat = require("policy.combat.monster_habitat")
local health = require("policy.combat.player_health")
local registry = require("policy.magic.effects.registry")

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

local function key(x, y)
    return x .. ":" .. y
end

local function distance(x, y, origin)
    return math.max(math.abs(x - origin.x), math.abs(y - origin.y))
end

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

local function integrated_damage(age)
    if age <= 0 then
        return 0
    end

    if age < 10 then
        return math.floor(age * age / 2)
    end

    return age * 10 - 50
end

local function ring_duration(age, elapsed, ring)
    local effective = age - math.floor(ring * ring * 7 / 5)

    return integrated_damage(effective + elapsed) -
        integrated_damage(effective)
end

local function wind_cells(ctx, origin)
    local level = origin.level_id
    local depth = {}
    local cuts = {}
    local cells = {}

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

local function angle(x, y)
    if math.abs(x) > math.abs(y) then
        return x > 0 and y / x or 4 + y / x
    end

    return y > 0 and 2 - x / y or -2 - x / y
end

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

local function stationary(definition)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == "M_STATIONARY" then
            return true
        end
    end

    return false
end

local function can_move(ctx, actor)
    if actor == ctx:player() then
        return false
    end

    local monster = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", monster.kind_id)

    return not stationary(definition) and
        not ctx:has(actor, component.MONSTER_VILE_CLUTCH) and
        not ctx:has(actor, component.GRASPING_ROOTS)
end

local function cold_damage(ctx, actor, ring_power)
    local rolled = 0

    for _ = 1, 12 do
        rolled = rolled + 1 + ctx:random("spell", ring_power)
    end

    local raw = random_round(ctx, rolled, 15)
    local maximum = math.max(1, math.floor(12 * ring_power / 15))

    if actor == ctx:player() then
        local adjusted = damage.player_elemental(ctx, actor, raw,
            "MR_RES_COLD")
        local amount = damage.player_proportional_armour(ctx,
            actor, adjusted, maximum)

        health.damage(ctx, actor, amount)
        return
    end

    local adjusted = damage.monster_elemental(ctx, actor, raw,
        "MR_RES_COLD")
    local amount = damage.monster_proportional_armour(ctx,
        actor, adjusted, maximum)

    damage.apply(ctx, actor, amount)
end

local function available_cell(ctx, level, actor, x, y, moving)
    if not habitat.at(ctx, actor, level, x, y) then
        return false
    end

    local occupant = ctx:actor_at(level, x, y)

    return occupant == nil or moving[occupant]
end

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

function vortex.resolve(ctx, player, _, _, power)
    local value = {
        remaining_aut = 60,
        started_aut = ctx:aut(),
        power = power,
    }

    if ctx:has(player, zap_ids.component.POLAR_VORTEX) then
        ctx:set(player, zap_ids.component.POLAR_VORTEX, value)
    else
        ctx:add(player, zap_ids.component.POLAR_VORTEX, value)
    end

    local flying = ctx:get(player, component.ZAP_FLIGHT)

    if flying then
        flying.remaining_aut = math.max(flying.remaining_aut, 60)
        ctx:set(player, component.ZAP_FLIGHT, flying)
    else
        ctx:add(player, component.ZAP_FLIGHT, { remaining_aut = 60 })
    end

    ctx:emit("spell", "A great freezing vortex appears around you!")
end

function vortex.tick(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local state = ctx:get(actor, zap_ids.component.POLAR_VORTEX)

    local flying = ctx:get(actor, component.ZAP_FLIGHT)

    if flying then
        flying.remaining_aut = math.max(0, flying.remaining_aut - aut)

        if flying.remaining_aut == 0 then
            ctx:remove(actor, component.ZAP_FLIGHT)
        else
            ctx:set(actor, component.ZAP_FLIGHT, flying)
        end
    end

    if not state then
        return
    end

    local origin = ctx:get(actor, component.POSITION)
    local winds = wind_cells(ctx, origin)
    local age = math.max(0, ctx:aut() - state.started_aut)
    local open = 0
    local all = 0
    local candidates = {}
    local available = {}

    for ring = 1, radius do
        local ring_cells = {}

        for dy = -ring, ring do
            for dx = -ring, ring do
                if math.max(math.abs(dx), math.abs(dy)) == ring then
                    local x = origin.x + dx
                    local y = origin.y + dy

                    if ctx:cell(origin.level_id, x, y) then
                        ring_cells[#ring_cells + 1] = { x = x, y = y }
                        all = all + 1

                        if winds[key(x, y)] then
                            open = open + 1
                        end
                    end
                end
            end
        end

        local duration = ring_duration(age, aut, ring)
        local power = random_round(ctx,
            state.power * open * duration, all * 100)

        if power <= 0 then
            break
        end

        for _, cell in ipairs(ring_cells) do
            local feature = ctx:cell(origin.level_id, cell.x, cell.y)

            if trees[feature] and ctx:random("spell", 2000) < duration then
                ctx:set_cell(origin.level_id, cell.x, cell.y, terrain.DNGN_FLOOR)
                ctx:emit("spell", "A tree falls to the furious winds!")
            end

            if winds[key(cell.x, cell.y)] then
                local victim = ctx:actor_at(origin.level_id, cell.x, cell.y)

                if victim then
                    cold_damage(ctx, victim, power)

                    local current = ctx:get(victim, component.HEALTH)

                    if current and current.current > 0 and
                        can_move(ctx, victim) then
                        candidates[#candidates + 1] = {
                            actor = victim,
                            position = cell,
                            ring_duration = duration,
                        }
                    end
                end

                if ctx:walkable(origin.level_id, cell.x, cell.y) then
                    available[#available + 1] = cell
                end
            end
        end
    end

    rotate(ctx, origin, candidates, available)
    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut <= 0 then
        ctx:remove(actor, zap_ids.component.POLAR_VORTEX)
        ctx:emit("duration", "The freezing vortex dissipates.")
    else
        ctx:set(actor, zap_ids.component.POLAR_VORTEX, state)
    end
end

registry.add(spells.SPELL_POLAR_VORTEX, vortex)

register.system({
    id = "zap.polar_vortex.tick",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = vortex.tick,
})

return vortex
