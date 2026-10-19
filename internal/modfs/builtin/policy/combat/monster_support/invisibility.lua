local component = require("constants.component")

local invisibility = {}

-- Perception and expiration read this one monster enchant record regardless
-- of whether the source was a self spell or an allied beam.
function invisibility.active(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENCHANT)

    return current ~= nil and current.invisible_aut > 0
end

-- Preserve unrelated blindness and corrosion while granting or extending
-- the recipient's saved invisibility timer.
function invisibility.grant(ctx, monster, duration)
    local current = ctx:get(monster, component.MONSTER_ENCHANT) or {
        blind_aut = 0,
        corrosion_aut = 0,
        invisible_aut = 0,
    }

    current.invisible_aut = math.max(current.invisible_aut, duration)

    if ctx:has(monster, component.MONSTER_ENCHANT) then
        ctx:set(monster, component.MONSTER_ENCHANT, current)
    else
        ctx:add(monster, component.MONSTER_ENCHANT, current)
    end
end

return invisibility
