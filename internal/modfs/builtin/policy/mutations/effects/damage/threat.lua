local component = require("constants.component")

local threat = {}

-- Source: ouch.cc:_is_damage_threatening uses pre-hit HP. The second
-- chance roll happens only when the first chance fails.
-- Example: a small hit below the safe-percent threshold cannot trigger an emergency response.
function threat.triggered(ctx, player, damage, level)
    local health = ctx:get(player, component.HEALTH)

    if not health or health.max <= 0 then
        error("damage safety requires player health")
    end

    local damage_percent = math.floor(damage * 100 / health.max)
    local hp_percent = math.floor(health.current * 100 / health.max)
    local safe_percent = level == 1 and 12 or 5
    local scary_percent = level == 1 and 50 or 20

    if damage_percent <= safe_percent or
        hp_percent > 100 - scary_percent + safe_percent then
        return false
    end

    if damage_percent + ctx:random("mutation", scary_percent) >=
        scary_percent then
        return true
    end

    return ctx:random("mutation", 100) > hp_percent
end

return threat
