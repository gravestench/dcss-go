-- The source Slime Pit's transparent inner walls are a durable game rule.
-- Every final clear stone source cell has a named DES marker and one saved
-- ECS seal cell. The terrain decoder may discard unchanged feature records.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local names = require("constants.slime_pit")

local slime_seal = {}

-- Use the placed source record, after all DES substitutions, so a changed
-- or absent wall never leaves a stale seal cell for the death callback.
function slime_seal.is_record(record)
    return record.kind == effects.MARKER and
        record.source_id == names.MAP_ID and
        record.identity == names.SEAL_MARKER
end

-- The marker owns its source index and mutable release bit; the terrain
-- grid remains the authoritative visible wall or floor.
function slime_seal.materialize(ctx, level, record)
    local entity = ctx:create()

    ctx:add(entity, component.SLIME_SEAL, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        record_index = record.index,
        released = false,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

return slime_seal
