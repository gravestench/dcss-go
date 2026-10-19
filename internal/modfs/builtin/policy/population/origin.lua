-- Example: Two spawned copies receive distinct occurrences but the same placement site.
-- Copies the placement site for each dynamic object created by one record.
local origin = {}

origin.CORPSE_OCCURRENCE = 1000

-- Copy the record position and occurrence into each materialized object for source tracing.
function origin.for_entity(source, kind_id, occurrence)
    return {
        level_id = source.level_id,
        vault_id = source.vault_id,
        kind_id = kind_id,
        record_index = source.record_index,
        occurrence = occurrence or source.occurrence or 1,
        spawn_x = source.spawn_x,
        spawn_y = source.spawn_y,
    }
end

return origin
