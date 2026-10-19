local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local groups = require("constants.monster_groups")
local holiness = require("constants.monster_holiness")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local range = require("policy.magic.range")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local trajectory = require("policy.combat.trajectory")
local attitudes = require("constants.attitude")

local ally_target = {}

-- Source flags and holiness are catalog arrays, not keyed Lua sets.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Harmless stationary no-threat monsters are source "firewood". Tentacles
-- and diagnostic test monsters remain eligible despite similar flags.
local function firewood(definition)
    return has(definition.flags, flags.STATIONARY) and
        has(definition.flags, flags.NO_THREAT) and
        not groups.tentacles[definition.id] and
        not groups.test_monsters[definition.id]
end

-- Source compares the caster's temporary side with the recipient's real
-- side. This excludes a newly charmed foe but retains an already friendly
-- recipient that happens to be charmed. Neutral actors are never allies.
local function aligned(ctx, caster, candidate)
    if targets.enemy(ctx, caster, candidate) or
        targets.allied(ctx, caster) ~=
            targets.real_allied(ctx, candidate) then
        return false
    end

    for _, entity in ipairs({ caster, candidate }) do
        local authored = ctx:get(entity,
            component.VAULT_ACTOR_OVERRIDES)

        if authored and authored.attitude == attitudes.NEUTRAL then
            return false
        end
    end

    return true
end

-- The source allows three special casters to help any genuine ally;
-- otherwise it uses holiness, the Naga/Snake order, or shared genus.
local function similar(caster, candidate)
    if caster.id == monsters.MONS_IRONBOUND_CONVOKER or
        caster.id == monsters.MONS_AMAEMON or
        caster.id == monsters.MONS_BOUND_SOUL then
        return true
    end

    if has(caster.holiness, holiness.HOLY) and
        has(candidate.holiness, holiness.HOLY) then
        return true
    end

    if caster.genus_id == monsters.MONS_NAGA and
        candidate.genus_id == monsters.MONS_SNAKE then
        return true
    end

    return caster.genus_id == candidate.genus_id
end

-- Query the current actor state; catalog identity alone cannot prove a
-- living target is positioned on the caster's active level.
local function candidate(ctx, caster, other, caster_definition,
    origin)
    if other == caster or other == ctx:player() or
        not aligned(ctx, caster, other) then
        return nil
    end

    local actor = ctx:get(other, component.ACTOR)
    local position = ctx:get(other, component.POSITION)
    local health = ctx:get(other, component.HEALTH)

    if not actor or not position or not health or health.current <= 0 or
        position.level_id ~= origin.level_id then
        return nil
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if firewood(definition) or
        not similar(caster_definition, definition) then
        return nil
    end

    return position
end

-- Beneficial beams stop at their first actor. Reuse the production grid ray
-- so a wall or earlier occupant cannot let the selected ally receive magic.
local function clear_ray(ctx, other, origin, position, reach)
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, position.x, position.y, reach)
    local contact = ray.contacts[1]

    return not ray.blocked and contact and contact.actor == other
end

-- Source _get_allied_target takes the nearest useful, genuinely allied
-- monster strictly inside beam range. Stable ECS order breaks equal ties.
function ally_target.plan(ctx, caster, spell_id, benefits)
    local origin = ctx:get(caster, component.POSITION)
    local actor = ctx:get(caster, component.ACTOR)

    if not origin or not actor then
        return nil
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local spell = catalog.get(categories.SPELLS, spell_id)
    local reach = range.for_power(spell, 0)
    local best = nil
    local closest = reach

    for _, other in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = candidate(ctx, caster, other,
            definition, origin)

        if position and benefits(ctx, other) then
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if distance < closest and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    reach, position.x, position.y) and
                clear_ray(ctx, other, origin, position,
                    reach) then
                best = other
                closest = distance
            end
        end
    end

    if not best then
        return nil
    end

    local position = ctx:get(best, component.POSITION)

    return {
        kind = target_kind.ENTITY,
        entity = best,
        dx = position.x - origin.x,
        dy = position.y - origin.y,
    }
end

-- A saved intent names one entity. If it is gone, moved, or intercepted,
-- resolution spends the cast without redirecting its effect to another actor.
function ally_target.selected(ctx, caster, plan)
    if not plan or plan.kind ~= target_kind.ENTITY then
        return nil
    end

    local origin = ctx:get(caster, component.POSITION)
    local position = ctx:get(plan.entity, component.POSITION)
    local health = ctx:get(plan.entity, component.HEALTH)

    if not origin or not position or not health or health.current <= 0 or
        origin.level_id ~= position.level_id then
        return nil
    end

    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    -- The scheduler persists the selected ray direction. A target that
    -- leaves its original endpoint must not receive a newly aimed beam.
    if position.x - origin.x ~= plan.dx or
        position.y - origin.y ~= plan.dy then
        return nil
    end

    if not clear_ray(ctx, plan.entity, origin, position,
        distance) then
        return nil
    end

    return plan.entity
end

return ally_target
