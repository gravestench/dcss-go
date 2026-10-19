-- Lightweight assertions report the failed policy invariant; the random
-- proxy consumes fixed mutation draws and rejects wrong streams or bounds.

local harness = {}

-- Raise at the caller's frame with both values, so a failed Lua assertion
-- points to the policy test rather than this shared helper.
function harness.equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " ..
            tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

-- Treat Lua's false and nil as failed assertions while preserving the
-- caller's diagnostic label for scenario-specific failures.
function harness.truthy(value, message)
    if not value then
        error(message or "expected a truthy value", 2)
    end
end

-- Require a false or nil result for rejection cases, reporting from the
-- calling test so its invalid input is easy to find.
function harness.falsy(value, message)
    if value then
        error(message or "expected a falsy value", 2)
    end
end

-- Create a minimal real ECS actor with one component, avoiding hand-built
-- duplicate schemas in policy tests.
function harness.actor_with(ctx, component_id, fields)
    local actor = ctx:create()

    ctx:add(actor, component_id, fields)

    return actor
end

-- Bound-one draws consume no fixture entry, matching random2(1) behavior.
function harness.random_context(ctx, draws)
    local next_draw = 0
    local proxy = setmetatable({}, { __index = ctx })

    -- Replay mutation draws in order and reject wrong streams or bounds,
    -- exposing seeded-rule drift at the exact requested draw.
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

    -- Report how far a rule advanced the supplied draw sequence, because
    -- extra RNG consumption can alter later gameplay even when results match.
    function proxy.draws_used()
        return next_draw
    end

    return proxy
end

return harness
