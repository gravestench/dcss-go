local component = require("constants.component")
local spells = require("ids.spells")
local terrain = require("constants.terrain")
local catalog = require("policy.catalog")
local explosion = require("policy.combat.explosion")
local roll = require("policy.combat.roll")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local targets = require("policy.ai.targets")

local fastroot = {}

local unsafe_floor = {
    [terrain.DNGN_DEEP_WATER] = true,
    [terrain.DNGN_SHALLOW_WATER] = true,
    [terrain.DNGN_LAVA] = true,
}

-- Absent monster flags grant no insubstantial immunity to roots.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Round grip and duration fractions on spell RNG so small power still has unbiased odds.
local function random_round(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        quotient = quotient + 1
    end

    return quotient
end

-- Roots cannot grip insubstantial or already constrained monsters, or those standing in unsafe terrain.
local function eligible(ctx, target, definition)
    local position = ctx:get(target, component.POSITION)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    return not unsafe_floor[feature] and
        not has(definition.flags, "M_INSUBSTANTIAL") and
        not ctx:has(target, component.CONSTRICTION) and
        not ctx:has(target, component.MONSTER_VILE_CLUTCH) and
        not ctx:has(target, component.GRASPING_ROOTS)
end

-- Reject self and unseen out-of-range aims before committing spell resources.
function fastroot.prepare(ctx, player, spell, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    if dx == 0 and dy == 0 or
        math.max(math.abs(dx), math.abs(dy)) > reach then
        return "The roots cannot reach there."
    end

    if not ctx:visible(origin.level_id, origin.x, origin.y, reach,
        origin.x + dx, origin.y + dy) then
        return "The roots cannot reach there."
    end
end

-- Center the radius-one roots on the first ray contact or endpoint, then hold only eligible enemies.
function fastroot.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]
    local x = contact and contact.x or ray.x
    local y = contact and contact.y or ray.y

    ctx:emit("spell", "The roots erupt in riotous growth!")

    for _, cell in ipairs(explosion.cells(ctx, origin.level_id, x, y, 1)) do
        local target = ctx:actor_at(origin.level_id, cell.x, cell.y)

        if target and targets.enemy(ctx, player, target) then
            local actor = ctx:get(target, component.ACTOR)
            local health = ctx:get(target, component.HEALTH)

            if actor and health and health.current > 0 then
                local definition = catalog.get("monsters", actor.kind_id)

                if eligible(ctx, target, definition) then
                    local average = roll.average_two(ctx, "spell",
                        random_round(ctx, power, 10))
                    local turns = 2 + average

                    ctx:add(target, component.GRASPING_ROOTS, {
                        remaining_aut = turns * 10,
                        power = power,
                        held_aut = 0,
                        escape_attempts = 0,
                    })
                    ctx:emit("warning", "Grasping roots grab the " ..
                        definition.name .. ".")
                end
            end
        end
    end
end

-- The monster remains held only while its saved root timer is positive.
function fastroot.restrained(ctx, monster)
    local state = ctx:get(monster, component.GRASPING_ROOTS)

    return state ~= nil and state.remaining_aut > 0
end

-- Example: A rooted monster rolls melee escape against its saved grip before movement.
-- Escape contests the stored grip using the melee RNG stream.
function fastroot.escape(ctx, monster)
    local state = ctx:get(monster, component.GRASPING_ROOTS)

    if not state or state.remaining_aut <= 0 then
        return true
    end

    state.escape_attempts = state.escape_attempts + 1
    local bound = 10 + random_round(ctx, state.power, 5)
    local grip = 1 + ctx:random("melee", bound)

    if 3 * state.escape_attempts > grip then
        ctx:remove(monster, component.GRASPING_ROOTS)
        ctx:emit("combat", "The grasping roots release their grip.")
        return true
    end

    ctx:set(monster, component.GRASPING_ROOTS, state)
    return false
end

-- Release a root at zero before the monster's next decision.
function fastroot.tick_monster(ctx, monster)
    local state = ctx:get(monster, component.GRASPING_ROOTS)

    if not state then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - 10)

    if state.remaining_aut == 0 then
        ctx:remove(monster, component.GRASPING_ROOTS)
        ctx:emit("combat", "The grasping roots release their grip.")
    else
        ctx:set(monster, component.GRASPING_ROOTS, state)
    end
end

-- Each player action damages held monsters; held time ramps the roll before their armour applies.
function fastroot.damage_player_action(ctx, player, aut)
    local damage = require("policy.magic.damage")
    local defense = require("policy.combat.monster_defense")
    local origin = ctx:get(player, component.POSITION)

    for _, monster in ipairs(ctx:query({
        component.GRASPING_ROOTS, component.POSITION, component.HEALTH,
    })) do
        local state = ctx:get(monster, component.GRASPING_ROOTS)
        local position = ctx:get(monster, component.POSITION)
        local health = ctx:get(monster, component.HEALTH)

        if health.current > 0 and position.level_id == origin.level_id and
            ctx:visible(origin.level_id, origin.x, origin.y, 7,
                position.x, position.y) then
            local definition = catalog.get("monsters",
                ctx:get(monster, component.ACTOR).kind_id)
            local sides = math.max(1,
                random_round(ctx, 25 + state.power, 10))
            local base = 2 + ctx:random("melee", sides) +
                ctx:random("melee", sides)
            local ramp = random_round(ctx,
                base * math.min(state.held_aut, 50), 50)
            local ac = defense.armour(ctx, monster, definition)
            local amount = math.max(0, base + ramp -
                ctx:random("melee", 1 + math.floor(ac / 2)))

            if amount > 0 then
                damage.apply(ctx, monster, amount)
            end

            ctx:emit("combat", "The grasping roots constrict the " ..
                definition.name .. ".")
            state.held_aut = state.held_aut + aut
            ctx:set(monster, component.GRASPING_ROOTS, state)
        end
    end
end

-- Only player action time drives held-root damage, preserving the spell's timing.
function fastroot.update_player(ctx, actor, aut)
    if actor == ctx:player() then
        fastroot.damage_player_action(ctx, actor, aut)
    end
end

registry.add(spells.SPELL_FASTROOT, {
    prepare = fastroot.prepare,
    resolve = fastroot.resolve,
})

-- Theory of operation: Monster root timers expire before decision so a released actor may act that turn.
register.system({
    id = "zap.grasping_roots.decay",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = fastroot.tick_monster,
})

-- Theory of operation: Player-action root damage runs after spell attacks and before movement, using the elapsed aut.
register.system({
    id = "zap.grasping_roots.damage",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = fastroot.update_player,
})

return fastroot
