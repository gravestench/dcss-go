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
local rng_streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local attack_conduct = require("policy.religion.conduct.attack")

local iood = {}

-- Keep the orb's saved velocity at unit length; zero aim is rejected before launch.
local function normalized(x, y)
    local length = math.sqrt(x * x + y * y)

    if length == 0 then
        return 0, 0
    end

    return x / length, y / length
end

-- Stochastic spell rounding keeps short-range power loss unbiased.
local function random_round(ctx, numerator, denominator, stream)
    local result = math.floor(numerator / denominator)

    if ctx:random(stream, denominator) < numerator % denominator then
        result = result + 1
    end

    return result
end

-- An Orb of Destruction fired at very short range loses power before its nine damage dice are rolled.
local function dice(ctx, power, distance, stream)
    local flat = 60

    if distance < 4 then
        power = random_round(ctx, power * distance * 3, 10, stream)
        flat = random_round(ctx, flat * distance * 3, 10, stream)
    end

    local sides = math.max(1, random_round(ctx, flat + power, 12, stream))
    local rolled = 0

    for _ = 1, 9 do
        rolled = rolled + 1 + ctx:random(stream, sides)
    end

    return rolled
end

-- Damage every occupied blast cell separately so each actor gets its own dice and armour roll.
local function burst(ctx, owner, level, x, y, power, distance, stream)
    ctx:emit("spell", "The orb of destruction explodes!")

    for _, cell in ipairs(explosion.cells(ctx, level, x, y, 1)) do
        local victim = ctx:actor_at(level, cell.x, cell.y)

        if victim then
            local raw = dice(ctx, power, distance, stream)

            if ctx:has(victim, component.PLAYER) then
                local amount = damage.player_armour(ctx, victim, raw,
                    nil, stream)

                health.damage(ctx, victim, amount, false, owner)
            else
                local definition, current = damage.monster(ctx, victim)

                if definition and current.current > 0 then
                    if owner == ctx:player() then
                        attack_conduct.report(ctx, victim, definition)
                    end

                    local ac = defense.armour(ctx, victim, definition)
                    local amount = math.max(0, raw -
                        ctx:random(stream, ac + 1))

                    damage.apply(ctx, victim, amount, owner)
                end
            end
        end
    end
end

-- Stop homing when the saved entity no longer has a live positioned actor.
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

-- The orb steers from saved trajectory state rather than snapping to a moving target.
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

-- Advance floating trajectory before rounding to a grid cell, preserving smooth steering.
local function next_position(state)
    state.x = state.x + state.vx
    state.y = state.y + state.vy
    state.distance = state.distance + 1

    return math.floor(state.x + 0.5), math.floor(state.y + 0.5)
end

-- Use summon expiry so orb components and ownership are cleaned up together.
local function dismiss(ctx, orb)
    summons.expire(ctx, orb)
end

-- An orb keeps only its owner in the summon component. The owner kind is
-- stable across save/restore, so the stream needs no duplicate saved field.
local function owner_stream(ctx, owner)
    if ctx:has(owner, component.PLAYER) then
        return rng_streams.SPELL
    end

    return rng_streams.MONSTER_SPELL
end

-- Curve after launch, then burst on terrain or actor collision; distant or off-map orbs dissipate.
local function move(ctx, orb, owner, state, initial)
    local position = ctx:get(orb, component.POSITION)
    local owner_position = ctx:get(owner, component.POSITION)

    if not initial then
        curve_toward_target(ctx, state)
    end

    local x, y = next_position(state)

    local flawed = ctx:has(owner, component.PLAYER)
    local too_far = flawed and (not owner_position or
        math.max(math.abs(owner_position.x - x),
            math.abs(owner_position.y - y)) > 7)

    -- Source monster orbs lack the flawed-player-orb distance limit.
    -- Their trajectory can continue even after the caster moves away.
    if not ctx:cell(position.level_id, x, y) or too_far then
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
            state.power, state.distance, owner_stream(ctx, owner))
        return true
    end

    ctx:move_actor(orb, position.level_id, x, y)
    ctx:set(orb, zap_ids.component.IOOD, state)

    return false
end

-- Reject self aim and out-of-range offsets before cast resources are committed.
function iood.prepare(ctx, player, spell, dx, dy)
    local reach = range.for_spell(ctx, player, spell)

    if dx == 0 and dy == 0 or
        math.max(math.abs(dx), math.abs(dy)) > reach then
        return "You cannot aim the orb there."
    end
end

-- Both player and monster casts use one trajectory and blast owner. Only
-- their aim, source and RNG stream differ; this avoids divergent IOOD rules.
function iood.launch(ctx, caster, dx, dy, power, target, stream)
    local origin = ctx:get(caster, component.POSITION)
    local vx, vy = normalized(dx, dy)
    local tangent = (ctx:random(stream, 31) - 15) * 0.019 *
        75 / math.max(10, power)
    local off = ctx:random(stream, 2) == 0 and -0.25 or 0.25
    local state = {
        x = origin.x + vy * off,
        y = origin.y - vx * off,
        vx = vx + vy * tangent,
        vy = vy - vx * tangent,
        distance = 0,
        power = power,
        target = target or ctx:actor_at(origin.level_id,
            origin.x + dx, origin.y + dy),
    }

    state.vx, state.vy = normalized(state.vx, state.vy)
    local x, y = next_position(state)

    if not ctx:cell(origin.level_id, x, y) then
        ctx:emit("spell", "The orb dissipates beyond the dungeon edge.")
        return
    end

    if not ctx:walkable(origin.level_id, x, y) or
        ctx:actor_at(origin.level_id, x, y) then
        burst(ctx, caster, origin.level_id, x, y,
            state.power, state.distance, stream)
        return
    end

    local orb = summons.spawn(ctx, caster, spells.SPELL_IOOD,
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

-- Player aim is a relative offset; the monster owner supplies its selected
-- foe explicitly so a moving target remains the saved homing entity.
function iood.resolve(ctx, player, intent, _, power)
    return iood.launch(ctx, player, intent.dx, intent.dy, power,
        nil, rng_streams.SPELL)
end

-- Example: An orb moves from its saved state; failed motion queues its cleanup intent.
-- Orb movement is scheduled from its component state so it survives save/restore.
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

-- Theory of operation: Orbs move after summon decisions and before monsters.
-- Failed motion queues an intent for cleanup.
register.system({
    id = "zap.iood.action",
    scope = "active",
    query = {},
    after = { "magic.summon.construct_decision" },
    before = { "monster.decision" },
    update = iood.tick,
})

return iood
