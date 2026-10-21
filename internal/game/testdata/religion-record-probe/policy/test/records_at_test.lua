-- Integration probe: this uses the production Lua context API inside a real
-- Game runtime, so the test can inspect a level's saved records end to end.
local test = {}

-- Return the exact typed records at one coordinate. The Go integration test
-- asserts their identity and value types without duplicating the ECS schema.
function test.run(ctx, input)
    local records = ctx:records_at(input.level_id, input.x, input.y)

    if input.probe_copy and #records > 0 then
        records[1].arguments.god_id = "GOD_TAMPERED"
        records = ctx:records_at(input.level_id, input.x, input.y)
    end

    return {
        count = #records,
        records = records,
    }
end

register.policy({
    id = "test.records_at",
    run = test.run,
})

return test
