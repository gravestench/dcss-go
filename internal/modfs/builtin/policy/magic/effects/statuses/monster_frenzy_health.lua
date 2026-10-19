local component = require("constants.component")

local frenzy_health = {}

-- Source monster::scale_hp uses +1 before integer division. This keeps an
-- odd maximum stable after Berserker Rage inflates and then deflates it.
function frenzy_health.scale(ctx, target, numerator, denominator)
    local health = ctx:get(target, component.HEALTH)

    if not health then
        error("berserk monster has no health component")
    end

    health.current = math.max(1, math.floor(
        (health.current * numerator + 1) / denominator))
    health.max = math.max(1, math.floor(
        (health.max * numerator + 1) / denominator))
    health.current = math.min(health.current, health.max)
    ctx:set(target, component.HEALTH, health)
end

return frenzy_health
