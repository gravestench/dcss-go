-- Theory of operation: KPROP no_tele_into is level-cell intent retained
-- from DES. Random teleport searches must reject those cells, not merely
-- walkable terrain. Zonguldrok releases its whole mask when the D door
-- appears; that fact is the encounter's saved Akara state.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local properties = require("constants.vault_properties")

local landings = {}

-- Read the effective records at one cell. The source property remains
-- immutable; a live Zonguldrok door explicitly deactivates its mask.
function landings.allowed(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_ZONGULDROK,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_ZONGULDROK)

        if state.level_id == level_id and state.door_appeared then
            return true
        end
    end

    for _, record in ipairs(ctx:records_at(level_id, x, y)) do
        if record.kind == effects.PROPERTY and
            record.identity == properties.NO_TELE_INTO and
            not record.overridden then
            return false
        end
    end

    return true
end

return landings
