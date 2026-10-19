-- Monster Drain Life reaches every vulnerable body in LOS_NO_TRANS, then
-- heals its caster by HP actually taken. It has no single foe-directed ray.
-- Source: mon-cast.cc spell_to_logic, spl-damage.cc:_cast_los_attack_spell.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local display = require("policy.combat.monster_support.display")
local life = require("policy.combat.life_transfer")
local monster_stats = require("policy.combat.monster_stats")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7

-- The spell is centered on its caster and cannot pass opaque or clear
-- walls. Other actors do not block an area effect.
local function in_area(ctx, source, position)
    if source.level_id ~= position.level_id then
        return false
    end

    local distance = math.max(math.abs(source.x - position.x),
        math.abs(source.y - position.y))

    return distance <= SIGHT_RADIUS and
        ctx:visible_no_trans(source.level_id, source.x, source.y,
            SIGHT_RADIUS, position.x, position.y)
end

-- Source excludes all aligned actors, including the caster, before its AI
-- decides whether the area has an eligible body to drain.
function effect.plan(ctx, caster)
    local source = ctx:get(caster, component.POSITION)

    if not source then
        return nil
    end

    for _, actor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(actor, component.POSITION)
        local health = ctx:get(actor, component.HEALTH)

        if health.current > 0 and
            not targets.aligned(ctx, caster, actor) and
            in_area(ctx, source, position) and
            life.susceptible(ctx, actor) and
            life.resistance(ctx, actor) < 3 then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- Source ZAP_DRAIN_LIFE rolls one die with sides 10 + spell power. The
-- monster version uses spell HD directly, not the usual twelvefold scale.
local function raw_damage(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local sides = 10 + math.min(200, hd)

    return 1 + ctx:random(streams.MONSTER_SPELL, sides)
end

-- Recheck each body against current geometry and resistance. The source
-- applies AC before negative-energy resistance, then heals from the sum of
-- actual HP losses; it never heals from a resisted or absent target.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local source = ctx:get(caster, component.POSITION)

    if not source then
        error("Drain Life caster has no position")
    end

    local total = 0

    for _, actor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(actor, component.POSITION)
        local health = ctx:get(actor, component.HEALTH)

        if health.current > 0 and
            not targets.aligned(ctx, caster, actor) and
            in_area(ctx, source, position) and
            life.susceptible(ctx, actor) and
            life.resistance(ctx, actor) < 3 then
            local raw = direct.armour(ctx, actor,
                raw_damage(ctx, caster))

            total = total + life.hurt(ctx, caster, actor, raw)
        end
    end

    if total <= 0 then
        return 0
    end

    local gained = life.heal(ctx, caster, total)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " draws from the surrounding life force!")
    elseif senses.player_sees_cell(ctx, source) then
        ctx:emit(channels.SPELL,
            "The surrounding life force dissipates!")
    end

    if gained > 0 and senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL, "The " .. display.name(ctx, caster) ..
            " is healed.")
    end

    return total
end

return effect
