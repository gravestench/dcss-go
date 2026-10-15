local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local damage = require("policy.magic.damage")
local defense = require("policy.combat.monster_defense")
local explosion = require("policy.combat.explosion")
local health = require("policy.combat.player_health")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local iood = {}

local function normalized(x, y)
    local length = math.sqrt(x * x + y * y)

    if length == 0 then
        return 0, 0
    end

    return x / length, y / length
end

local function random_round(ctx, numerator, denominator)
    local result = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        result = result + 1
    end

    return result
end

local function dice(ctx, power, distance)
    local flat = 60

    if distance < 4 then
        power = random_round(ctx, power * distance * 3, 10)
        flat = random_round(ctx, flat * distance * 3, 10)
    end

    local sides = math.max(1, random_round(ctx, flat + power, 12))
    local rolled = 0

    for _ = 1, 9 do
        rolled = rolled + 1 + ctx:random("spell", sides)
    end

    return rolled
end

local function burst(ctx, owner, level, x, y, power, distance)
    ctx:emit("spell", "The orb of destruction explodes!")

    for _, cell in ipairs(explosion.cells(ctx, level, x, y, 1)) do
        local victim = ctx:actor_at(level, cell.x, cell.y)

        if victim then
            local raw = dice(ctx, power, distance)

            if victim == owner then
                local amount = damage.player_armour(ctx, owner, raw)

                health.damage(ctx, owner, amount)
            else
                local definition, current = damage.monster(ctx, victim)

                if definition and current.current > 0 then
                    local ac = defense.armour(ctx, victim, definition)
                    local amount = math.max(0, raw -
                        ctx:random("spell", ac + 1))

                    damage.apply(ctx, victim, amount)
                end
            end
        end
    end
end

local function active_target(ctx, state)
    if not state.target or ctx:id(state.target) == 0 then
        return nil
    end

    local position = ctx:get(state.target, component.POSITION)
    local current = ctx:get(state.target, component.HEALTH)

    if current and current.current > 0 then
        return position
    end

    return nil
end

local function curve_toward_target(ctx, state)
    local target = active_target(ctx, state)

    if not target then
        state.target = nil
        return
    end

    local dx, dy = normalized(target.x - state.x,
        target.y - state.y)
    local distance = (dx - state.vx) ^ 2 + (dy - state.vy) ^ 2

    if distance <= 0.09 then
        return
    end

    local cross = dy * state.vx - dx * state.vy
    local ax = cross < 0 and state.vy or -state.vy
    local ay = cross < 0 and -state.vx or state.vx

    state.vx, state.vy = normalized(state.vx + ax * 0.3,
        state.vy + ay * 0.3)
end

local function next_position(state)
    state.x = state.x + state.vx
    state.y = state.y + state.vy
    state.distance = state.distance + 1

    return math.floor(state.x + 0.5), math.floor(state.y + 0.5)
end

local function dismiss(ctx, orb)
    summons.expire(ctx, orb)
end

local function move(ctx, orb, owner, state, initial)
    local position = ctx:get(orb, component.POSITION)
    local owner_position = ctx:get(owner, component.POSITION)

    if not initial then
        curve_toward_target(ctx, state)
    end

    local x, y = next_position(state)

    if not ctx:cell(position.level_id, x, y) or
        not owner_position or
        math.max(math.abs(owner_position.x - x),
            math.abs(owner_position.y - y)) > 7 then
        dismiss(ctx, orb)
        return true
    end

    if x == position.x and y == position.y then
        ctx:set(orb, zap_ids.component.IOOD, state)
        return false
    end

    local victim = ctx:actor_at(position.level_id, x, y)

    if not ctx:walkable(position.level_id, x, y) or victim then
        dismiss(ctx, orb)
        burst(ctx, owner, position.level_id, x, y,
            state.power, state.distance)
        return true
    end

    ctx:move_actor(orb, position.level_id, x, y)
    ctx:set(orb, zap_ids.component.IOOD, state)

    return false
end

function iood.prepare(ctx, player, spell, dx, dy)
    local reach = range.for_spell(ctx, player, spell)

    if dx == 0 and dy == 0 or
        math.max(math.abs(dx), math.abs(dy)) > reach then
        return "You cannot aim the orb there."
    end
end

function iood.resolve(ctx, player, intent, _, power)
    local origin = ctx:get(player, component.POSITION)
    local vx, vy = normalized(intent.dx, intent.dy)
    local tangent = (ctx:random("spell", 31) - 15) * 0.019 *
        75 / math.max(10, power)
    local off = ctx:random("spell", 2) == 0 and -0.25 or 0.25
    local state = {
        x = origin.x + vy * off,
        y = origin.y - vx * off,
        vx = vx + vy * tangent,
        vy = vy - vx * tangent,
        distance = 0,
        power = power,
        target = ctx:actor_at(origin.level_id,
            origin.x + intent.dx, origin.y + intent.dy),
    }

    state.vx, state.vy = normalized(state.vx, state.vy)
    local x, y = next_position(state)

    if not ctx:cell(origin.level_id, x, y) then
        ctx:emit("spell", "The orb dissipates beyond the dungeon edge.")
        return
    end

    if not ctx:walkable(origin.level_id, x, y) or
        ctx:actor_at(origin.level_id, x, y) then
        burst(ctx, player, origin.level_id, x, y,
            state.power, state.distance)
        return
    end

    local orb = summons.spawn(ctx, player, spells.SPELL_IOOD,
        monsters.MONS_ORB_OF_DESTRUCTION, 0, 999, {
            anchor = origin,
            exact = { x = x, y = y },
            expires_aut = ctx:aut() + 200,
        })

    if not orb then
        error("orb of destruction could not occupy its first cell")
    end

    ctx:add(orb, zap_ids.component.IOOD, state)
    ctx:emit("spell", "An orb of destruction launches!")
end

function iood.tick(ctx, orb)
    local state = ctx:get(orb, zap_ids.component.IOOD)

    if not state then
        return
    end

    local owner = ctx:get(orb, component.SUMMON).owner

    if not move(ctx, orb, owner, state, false) then
        ctx:add(orb, component.INTENT, { kind = 6 })
    end
end

registry.add(spells.SPELL_IOOD, iood)

register.system({
    id = "zap.iood.action",
    scope = "active",
    query = {},
    after = { "magic.summon.construct_decision" },
    before = { "monster.decision" },
    update = iood.tick,
})

return iood
