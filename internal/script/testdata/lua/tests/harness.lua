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

function harness.random_context(ctx, draws)
    local next_draw = 0
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.random(_, stream, bound)
        if stream ~= "mutation" then
            error("unexpected random stream " .. tostring(stream))
        end

        if bound == 1 then
            return 0
        end

        next_draw = next_draw + 1
        local value = draws[next_draw]

        if type(value) ~= "number" or value < 0 or value >= bound then
            error("invalid fixture draw " .. tostring(next_draw) ..
                " for bound " .. tostring(bound))
        end

        return value
    end

    function proxy.draws_used()
        return next_draw
    end

    return proxy
end

return harness
