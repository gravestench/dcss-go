-- Every source callback family has one clock marker per placed floor.
-- Check that fact during population, while portal entry can still roll
-- back, rather than discovering a duplicate only when a save restores.
local effects = require("constants.vault_effects")

local group = {}

-- A duplicate clock creates two Akara owners and makes the floor
-- unrestorable. The caller supplies the family name for a useful mod
-- error; record identity and source ID are the actual ownership keys.
function group.require_unique_clock(level, record, family)
    local count = 0

    for _, candidate in ipairs(level.vault_records or {}) do
        if candidate.source_id == record.source_id and
            candidate.kind == effects.MARKER and
            candidate.identity == record.identity and
            not candidate.overridden then
            count = count + 1
        end
    end

    if count ~= 1 then
        error("multiple " .. family .. " source clocks")
    end
end

return group
