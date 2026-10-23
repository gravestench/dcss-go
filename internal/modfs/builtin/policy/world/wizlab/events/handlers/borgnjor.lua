-- Theory of operation: an authored A marker enables the lost-soul
-- callback for this floor. It creates an ECS witness at population;
-- the death hook later reads that witness rather than checking a name.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local source_group = require("policy.world.wizlab.events.source_group")
local wizlab = require("constants.wizlab")

local handler = {
    id = "borgnjor",
}

-- No other vault's A marker may claim this source callback.
function handler.is_marker(record)
    return record.source_id == wizlab.BORGNJOR_MAP_ID and
        record.kind == effects.MARKER and
        record.identity == wizlab.BORGNJOR_SOUL_MARKER
end

-- Preserve the transformed source position and record index in Akara.
function handler.materialize(ctx, level, record)
    source_group.require_unique_clock(level, record, "Borgnjor")

    local entity = ctx:create()

    ctx:add(entity, component.WORLD_WIZLAB_BORGNJOR, {
        level_id = level.id,
        vault_id = record.source_id,
        marker_index = record.index,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

return handler
