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
local flags = require("constants.monster_flags")
local form_ids = require("constants.form_ids")
local mutations = require("ids.mutations")
local monsters = require("ids.monsters")
local mutation_levels = require("policy.mutations.levels")

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

-- Source indirect constriction requires solid ground, sight, and a body
-- that is neither insubstantial nor already under another constriction.
function fastroot.eligible(ctx, caster, target)
    local position = ctx:get(target, component.POSITION)
    local origin = ctx:get(caster, component.POSITION)
    local health = ctx:get(target, component.HEALTH)

    if not position or not origin or not health or
        health.current <= 0 or origin.level_id ~= position.level_id or
        not ctx:visible(position.level_id,
            origin.x, origin.y, 7,
            position.x, position.y) then
        return false
    end

    local feature = ctx:cell(position.level_id, position.x, position.y)

    if unsafe_floor[feature] or
        ctx:has(target, component.CONSTRICTION) or
        ctx:has(target, component.PLAYER_CONSTRICTION) or
        ctx:has(target, component.MONSTER_VILE_CLUTCH) or
        ctx:has(target, component.GRASPING_ROOTS) then
        return false
    end

    if ctx:has(target, component.PLAYER) then
        local form = ctx:get(target, component.PLAYER_FORM)

        if form and form.remaining_aut > 0 and
            (form.form_id == form_ids.WISP or
                form.form_id == form_ids.STORM) then
            return false
        end

        return mutation_levels.effective(ctx, target,
            mutations.MUT_SPINY) == 0
    end

    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return not has(definition.flags, flags.INSUBSTANTIAL) and
        not has(definition.flags, flags.SPINY) and
        definition.genus_id ~= monsters.MONS_JELLY
end

-- One saved root record serves player Fastroot and monster Grasping Roots.
-- Attaching the caster handle lets later actions damage the original foe.
function fastroot.apply(ctx, caster, target, turns, power)
    if not fastroot.eligible(ctx, caster, target) then
        return false
    end

    ctx:add(target, component.GRASPING_ROOTS, {
        source = caster,
        remaining_aut = turns * 10,
        power = power,
        held_aut = 0,
        escape_attempts = 0,
    })

    if ctx:has(target, component.PLAYER) then
        ctx:emit("warning", "The grasping roots grab you!")
    else
        local actor = ctx:get(target, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        ctx:emit("warning", "Grasping roots grab the " ..
            definition.name .. ".")
    end

    return true
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
                if fastroot.eligible(ctx, player, target) then
                    local average = roll.average_two(ctx, "spell",
                        random_round(ctx, power, 10))
                    local turns = 2 + average

                    fastroot.apply(ctx, player, target, turns, power)
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

    -- A root cannot keep constricting after its source dies or leaves the
    -- victim's level. The source handle is saved, so never choose a new one.
    if state.source then
        local source_health = ctx:get(state.source, component.HEALTH)
        local source_position = ctx:get(state.source,
            component.POSITION)
        local victim_position = ctx:get(monster, component.POSITION)

        if not source_health or source_health.current <= 0 or
            not source_position or not victim_position or
            source_position.level_id ~= victim_position.level_id then
            ctx:remove(monster, component.GRASPING_ROOTS)
            ctx:emit("combat", "The grasping roots release their grip.")

            return
        end
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
function fastroot.damage_owner_action(ctx, caster, aut)
    local damage = require("policy.magic.damage")
    local defense = require("policy.combat.monster_defense")
    local direct = require("policy.combat.monster_direct")
    local fighter = require("policy.combat.fighter")
    local origin = ctx:get(caster, component.POSITION)
    local caster_health = ctx:get(caster, component.HEALTH)

    if not origin or not caster_health or caster_health.current <= 0 then
        return
    end

    for _, victim in ipairs(ctx:query({
        component.GRASPING_ROOTS, component.POSITION, component.HEALTH,
    })) do
        local state = ctx:get(victim, component.GRASPING_ROOTS)
        local position = ctx:get(victim, component.POSITION)
        local health = ctx:get(victim, component.HEALTH)

        if state.source == caster and health.current > 0 and
            position.level_id == origin.level_id and
            ctx:visible(origin.level_id, origin.x, origin.y, 7,
                position.x, position.y) then
            local player_caster = ctx:has(caster, component.PLAYER)
            local sides

            if player_caster then
                sides = math.max(1,
                    random_round(ctx, 25 + state.power, 10))
            else
                sides = math.max(1, roll.random_divide(ctx,
                    40 + state.power, 20, "melee"))
            end

            local base = 2 + ctx:random("melee", sides) +
                ctx:random("melee", sides)
            local ramp = random_round(ctx,
                base * math.min(state.held_aut, 50), 50)
            local ac

            if ctx:has(victim, component.PLAYER) then
                ac = fighter.defense(ctx).ac
            else
                local actor = ctx:get(victim, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)

                ac = defense.armour(ctx, victim, definition)
            end

            local amount = math.max(0, base + ramp -
                ctx:random("melee", 1 + math.floor(ac / 2)))

            if amount > 0 then
                if player_caster then
                    damage.apply(ctx, victim, amount, caster)
                else
                    direct.damage(ctx, caster, victim, amount)
                end
            end

            if ctx:has(victim, component.PLAYER) then
                ctx:emit("combat", "The grasping roots constrict you.")
            else
                local actor = ctx:get(victim, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)

                ctx:emit("combat", "The grasping roots constrict the " ..
                    definition.name .. ".")
            end

            state.held_aut = state.held_aut + aut
            ctx:set(victim, component.GRASPING_ROOTS, state)
        end
    end
end

-- Each caster's elapsed action time damages only victims it personally
-- rooted. This preserves spell attribution and prevents a global tick.
function fastroot.update_owner(ctx, actor, aut)
    fastroot.damage_owner_action(ctx, actor, aut)
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

-- Theory of operation: Every actor action constricts only roots bearing that
-- caster's ECS handle; the victim's own action separately ages the hold.
register.system({
    id = "zap.grasping_roots.damage",
    scope = "active",
    query = {},
    after = { "attack.player_spell", "attack.spell" },
    before = { "world.movement" },
    update = fastroot.update_owner,
})

return fastroot
