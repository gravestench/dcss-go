-- A saved nexus belongs to exactly one generated level cell. Its clock
-- can expire but cannot turn negative, move beyond the grid, or duplicate
-- another nexus. The marker persists to enforce once-per-floor use.
local component = require("constants.component")

local corruption = {}

-- Restore checks spatial and temporal state before ordinary turn systems
-- can read an untrusted marker or attempt an out-of-bounds spawn.
function corruption.validate(ctx)
    local occupied = {}

    for _, entity in ipairs(ctx:query({
        component.LUGONU_CORRUPTION_NEXUS,
    })) do
        local nexus = ctx:get(entity,
            component.LUGONU_CORRUPTION_NEXUS)
        local width, height = ctx:level_size(nexus.level_id)
        local key = nexus.level_id .. ":" .. nexus.x ..
            ":" .. nexus.y

        if not width or not height or
            nexus.x < 1 or nexus.y < 1 or
            nexus.x >= width - 1 or
            nexus.y >= height - 1 or
            nexus.remaining_aut < 0 or
            nexus.remaining_aut > 1500 or
            occupied[key] then
            error("invalid saved Lugonu corruption nexus")
        end

        occupied[key] = true
    end

    return {}
end

register.policy({
    id = "save.validate_lugonu_corruption",
    run = corruption.validate,
})

return corruption
