-- Exercise the generic saved-record string update through a real Game grid.
-- The host must match the source record and old value before staging a change.
local change = {}

-- Replace one typed string argument without exposing the level's record
-- slice to Lua. The caller controls identity, key, and expected value.
function change.run(ctx, input)
    ctx:replace_record_string(
        input.level_id,
        input.x,
        input.y,
        input.source_id,
        input.kind,
        input.identity,
        input.key,
        input.expected,
        input.replacement)

    return {}
end

register.policy({
    id = "test.change_record",
    run = change.run,
})

return change
