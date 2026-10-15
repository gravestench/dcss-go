local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local damage = require("policy.magic.damage")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local thunderbolt = {}

function thunderbolt.cell_order(a, b)
    return a.x < b.x or a.x == b.x and a.y < b.y
end

local function key(x, y)
    return x .. ":" .. y
end

local function distance(dx, dy)
    return math.max(math.abs(dx), math.abs(dy))
end

local function left_of(a, b)
    return a.x * b.y > a.y * b.x
end

local function random_round(ctx, numerator, denominator)
    local value = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        value = value + 1
    end

    return value
end

function thunderbolt.prepare(ctx, player, spell, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local x = origin.x + dx
    local y = origin.y + dy

    if dx == 0 and dy == 0 or distance(dx, dy) > reach or
        not ctx:cell(origin.level_id, x, y) or
        not ctx:projectile_clear(origin.level_id,
            origin.x, origin.y, x, y) then
        return "There's something in the way."
    end
end

local function geometry(ctx, origin, aim, prev, reach)
    local zapped = {}
    local lengths = {}

    local function add(x, y)
        local id = key(x, y)

        if not zapped[id] then
            local ring = distance(x - origin.x, y - origin.y)

            zapped[id] = { x = x, y = y, ring = ring }
            lengths[ring] = (lengths[ring] or 0) + 1
        end
    end

    local function ray(to)
        local result = trajectory.trace(ctx, origin.level_id,
            origin.x, origin.y, to.x, to.y, reach)

        for _, cell in ipairs(result.path) do
            add(cell.x, cell.y)
        end
    end

    ray(aim)

    if prev then
        ray(prev)

        local a = { x = prev.x - origin.x, y = prev.y - origin.y }
        local b = { x = aim.x - origin.x, y = aim.y - origin.y }

        if left_of(b, a) then
            a, b = b, a
        end

        for dy = -reach, reach do
            for dx = -reach, reach do
                local relative = { x = dx, y = dy }

                if left_of(a, relative) and left_of(relative, b) then
                    local x = origin.x + dx
                    local y = origin.y + dy

                    if ctx:cell(origin.level_id, x, y) and
                        ctx:projectile_clear(origin.level_id,
                            origin.x, origin.y, x, y) then
                        add(x, y)
                    end
                end
            end
        end
    end

    return zapped, lengths
end

function thunderbolt.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local turn = ctx:get(player, component.PLAYER_TURN).count + 1
    local state = ctx:get(player, zap_ids.component.THUNDERBOLT) or {
        last_turn = 0,
        origin_x = 0,
        origin_y = 0,
        aim_x = 0,
        aim_y = 0,
        charges = 0,
    }
    local prev

    if state.last_turn > 0 and state.last_turn + 1 == turn and
        state.origin_x == origin.x and state.origin_y == origin.y then
        prev = { x = state.aim_x, y = state.aim_y }
    else
        state.charges = 0
    end

    local aim = {
        x = origin.x + intent.dx,
        y = origin.y + intent.dy,
    }
    local zapped, lengths = geometry(ctx, origin, aim, prev,
        range.for_spell(ctx, player, spell))
    local count = spell.level + state.charges

    local ordered = {}

    for _, cell in pairs(zapped) do
        ordered[#ordered + 1] = cell
    end

    table.sort(ordered, thunderbolt.cell_order)

    for _, cell in ipairs(ordered) do
        local target = ctx:actor_at(origin.level_id, cell.x, cell.y)

        if target and target ~= player then
            local ring_length = lengths[cell.ring]
            local sides = random_round(ctx,
                30 + math.floor(power / 6), ring_length + 2)
            local raw = 0

            for _ = 1, count do
                raw = raw + 1 + ctx:random("spell", math.max(1, sides))
            end

            local after_ac = damage.monster_proportional_armour(ctx,
                target, raw, count * math.max(1, sides))
            local amount = damage.monster_elemental(ctx, target,
                after_ac, "MR_RES_ELEC")

            damage.apply(ctx, target, amount)
        end
    end

    state.last_turn = turn
    state.origin_x = origin.x
    state.origin_y = origin.y
    state.aim_x = aim.x
    state.aim_y = aim.y
    state.charges = math.min(4, state.charges + 1)

    if ctx:has(player, zap_ids.component.THUNDERBOLT) then
        ctx:set(player, zap_ids.component.THUNDERBOLT, state)
    else
        ctx:add(player, zap_ids.component.THUNDERBOLT, state)
    end

    ctx:emit("spell", "A thunderbolt arcs through the air!")
end

registry.add(spells.SPELL_THUNDERBOLT, thunderbolt)

return thunderbolt
