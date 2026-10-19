-- A boulder beetle's rolling enchantment changes later actions, not the
-- cast that grants it. Source: mon-cast.cc, mon-act.cc, and mon-ench.cc.
local cloud = require("policy.clouds.placement")
local clouds = require("ids.clouds")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local habitat = require("policy.combat.monster_habitat")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local streams = require("constants.rng_streams")

local roll = {}

-- A roll is useful only when a real move can close distance to the foe.
-- This mirrors the source MMOV check without consuming route RNG during
-- spell prospecting.
function roll.can_start(ctx, caster, foe)
    if ctx:has(caster, component.MONSTER_ROLLING) then
        return false
    end

    local source = ctx:get(caster, component.POSITION)
    local target = foe and ctx:get(foe, component.POSITION)

    if not source or not target or
        source.level_id ~= target.level_id then
        return false
    end

    local distance = math.max(math.abs(source.x - target.x),
        math.abs(source.y - target.y))

    if distance <= 1 then
        return false
    end

    for dy = -1, 1 do
        for dx = -1, 1 do
            local x = source.x + dx
            local y = source.y + dy
            local next_distance = math.max(math.abs(x - target.x),
                math.abs(y - target.y))

            if (dx ~= 0 or dy ~= 0) and
                next_distance < distance and
                not ctx:actor_at(source.level_id, x, y) and
                habitat.at(ctx, caster, source.level_id, x, y) then
                return true
            end
        end
    end

    return false
end

-- Source ENCH_ROLLING lasts 10–15 baseline turns. Its saved component
-- starts when the self spell resolves, ready for later monster actions.
function roll.start(ctx, caster)
    local duration = 100 + ctx:random(streams.MONSTER_SPELL, 51)

    ctx:add(caster, component.MONSTER_ROLLING, {
        remaining_aut = duration,
    })
    ctx:emit("combat", "The " .. display.name(ctx, caster) ..
        " curls into a ball and begins rolling!")
end

-- Spell and missile selection can ask the same actor-owned status rule.
function roll.active(ctx, caster)
    local state = ctx:get(caster, component.MONSTER_ROLLING)

    return state ~= nil and state.remaining_aut > 0
end

-- A moving roller leaves short, harmless dust at its new cell. The cloud
-- owner handles replacement, attribution, and save/restore.
function roll.moved(ctx, caster)
    if not roll.active(ctx, caster) then
        return
    end

    local position = ctx:get(caster, component.POSITION)

    cloud.place(ctx, clouds.CLOUD_DUST, caster,
        position.level_id, position.x, position.y, 20)
end

-- Source boulder beetles use a hit attack with doubled base damage while
-- rolling. Other damage modifiers still run through ordinary melee rules.
function roll.attack_damage(ctx, caster, base_damage)
    if roll.active(ctx, caster) then
        return base_damage * 2
    end

    return base_damage
end

-- Whether melee hits or misses, a completed contact uncurls the beetle.
function roll.finish_attack(ctx, caster)
    if not roll.active(ctx, caster) then
        return
    end

    ctx:remove(caster, component.MONSTER_ROLLING)
    ctx:emit("combat", "The " .. display.name(ctx, caster) ..
        " stops rolling and uncurls.")
end

-- A roller with no legal move also uncurls instead of waiting in place.
function roll.stalled(ctx, caster)
    roll.finish_attack(ctx, caster)
end

-- Enchantment time belongs to the active monster's action clock. Paralysis
-- and hibernation stop the rolling state in the source enchantment owner.
function roll.tick(ctx, caster, elapsed_aut)
    local state = ctx:get(caster, component.MONSTER_ROLLING)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - elapsed_aut

    if state.remaining_aut <= 0 or
        ctx:has(caster, component.PARALYSIS) or
        stasis.hibernating(ctx, caster) or
        stasis.petrified(ctx, caster) then
        roll.finish_attack(ctx, caster)
    else
        ctx:set(caster, component.MONSTER_ROLLING, state)
    end
end

return roll
