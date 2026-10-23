-- Source: spl-damage.cc:cast_toxic_radiance and toxic_radiance_effect.
local time = require("constants.time")
local component = require("constants.component")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local poison = require("policy.combat.monster_poison")
local common = require("policy.magic.effects.statuses.common")
local attack_conduct = require("policy.religion.conduct.attack")

local radiance = {}

-- Initialize all area timers together so Toxic Radiance can coexist with Corpse Rot and Bog.
local function status(ctx, player)
    return ctx:get(player, component.AREA_STATUS) or {
        corpse_rot_aut = 0,
        corpse_rot_power = 0,
        toxic_radiance_aut = 0,
        toxic_radiance_power = 0,
        noxious_bog_aut = 0,
    }
end

-- Example: a nearby susceptible monster receives poison each elapsed action
-- while the caster's saved radiance duration remains positive. Source
-- conduct is reported only on the cast pulse, never on later status ticks.
local function emit_poison(ctx, player, power, aut, on_cast)
    local origin = ctx:get(player, component.POSITION)
    local pulses = math.floor(aut / time.AUT_PER_TURN)
    local remainder = aut % time.AUT_PER_TURN

    if remainder > 0 and
        ctx:random("spell", time.AUT_PER_TURN) < remainder then
        pulses = pulses + 1
    end

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)

            if health.current > 0 and
                common.visible(ctx, origin, position) then
                local actor = ctx:get(monster, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)

                if on_cast then
                    attack_conduct.report(ctx, monster, definition)
                end

                if poison.resistance(definition) < 1 then
                    local raw = (1 + ctx:random("spell", 1 +
                        math.floor(power / 20))) * pulses
                    local amount = damage.monster_elemental(ctx, monster,
                        raw, "MR_RES_POISON")

                    if amount > 0 then
                        local remaining = damage.apply(ctx, monster, amount)

                        if remaining > 0 then
                            local levels = 0

                            for _ = 1, pulses do
                                levels = levels + ctx:random("spell", 2)
                            end

                            if not ctx:has(monster, component.PROJECTILE_POISON) then
                                levels = math.max(1, levels)
                            end

                            poison.apply(ctx, monster, definition,
                                levels, player, false)
                        end
                    end
                end
            end
        end
    end
end

-- Recasting extends area status instead of creating a second radiation source.
function radiance.cast(ctx, player, _, _, power)
    local value = status(ctx, player)
    local before = value.toxic_radiance_aut
    local extra = math.floor(power / 20)
    local added = 2 + (extra > 0 and ctx:random("spell", extra) or 0)

    value.toxic_radiance_aut = math.min(150,
        before + added * time.AUT_PER_TURN)
    value.toxic_radiance_power = power

    if ctx:has(player, component.AREA_STATUS) then
        ctx:set(player, component.AREA_STATUS, value)
    else
        ctx:add(player, component.AREA_STATUS, value)
    end

    ctx:emit("spell", before == 0 and
        "You begin to radiate toxic energy." or
        "Your toxic radiance grows in intensity.")
    emit_poison(ctx, player, power, time.AUT_PER_TURN, true)
end

-- Radiance continues poisoning nearby actors from a saved area-status duration.
function radiance.tick(ctx, player, aut)
    local value = ctx:get(player, component.AREA_STATUS)

    if not value or value.toxic_radiance_aut <= 0 or aut <= 0 then
        return
    end

    emit_poison(ctx, player, value.toxic_radiance_power,
        math.min(aut, value.toxic_radiance_aut))
end

return radiance
