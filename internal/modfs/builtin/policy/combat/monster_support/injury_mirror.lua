local causes = require("constants.damage_causes")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local roll = require("policy.combat.roll")

local mirror = {}

-- Damage reflection is active only while the saved aura timer is positive.
function mirror.active(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_INJURY_MIRROR)

    return state ~= nil and state.remaining_aut > 0
end

-- Source mon-cast.cc blocks recasting even after the aura has faded.
function mirror.ready(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_INJURY_MIRROR)

    return not state or state.remaining_aut == 0 and
        ctx:aut() >= state.recast_at_aut
end

-- The source sets 7-9 turns of aura and a 150-209 aut absolute recast clock.
function mirror.cast(ctx, monster)
    local state = {
        remaining_aut = 70 + 10 * roll.spell(ctx, 3),
        recast_at_aut = ctx:aut() + 150 + roll.spell(ctx, 60),
    }

    if ctx:has(monster, component.MONSTER_INJURY_MIRROR) then
        ctx:set(monster, component.MONSTER_INJURY_MIRROR, state)
    else
        ctx:add(monster, component.MONSTER_INJURY_MIRROR, state)
    end

    ctx:emit("spell", "The " .. display.name(ctx, monster) ..
        " fills with unholy mirror energy.")
end

-- Poison, clouds, and already returned damage never trigger a mirror.
-- The direct-damage owner calls this only after HP was actually lost.
function mirror.returned(ctx, monster, dealt, source, cause)
    if dealt <= 0 or not source or source == monster or
        cause == causes.POISON or cause == causes.CLOUD or
        cause == causes.REFLECTED or
        not mirror.active(ctx, monster) then
        return 0
    end

    local source_health = ctx:get(source, component.HEALTH)

    if not source_health or source_health.current <= 0 then
        return 0
    end

    return math.floor(dealt * 2 / 3)
end

-- Age only the aura. Keep the saved recast clock until its absolute time.
function mirror.tick(ctx, monster, elapsed_aut)
    local state = ctx:get(monster, component.MONSTER_INJURY_MIRROR)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 and
        ctx:aut() >= state.recast_at_aut then
        ctx:remove(monster, component.MONSTER_INJURY_MIRROR)
    else
        ctx:set(monster, component.MONSTER_INJURY_MIRROR, state)
    end
end

-- Unravelling removes the active aura without erasing its recast cooldown.
function mirror.dispel(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_INJURY_MIRROR)

    if not state or state.remaining_aut == 0 then
        return false
    end

    state.remaining_aut = 0
    ctx:set(monster, component.MONSTER_INJURY_MIRROR, state)

    return true
end

return mirror
