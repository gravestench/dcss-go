local harness = {}

function harness.equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " ..
            tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function harness.truthy(value, message)
    if not value then
        error(message or "expected a truthy value", 2)
    end
end

function harness.falsy(value, message)
    if value then
        error(message or "expected a falsy value", 2)
    end
end

function harness.actor_with(ctx, component_id, fields)
    local actor = ctx:create()

    ctx:add(actor, component_id, fields)

    return actor
end

return harness
