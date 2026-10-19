-- The route mutates context before returning an invalid screen, probing transaction rollback.

local play = {}

-- Stage an entity creation before returning an invalid destination. If route
-- validation fails, the terminal must discard that pending ECS command.
-- Example: play.route({ key = "z" }, ctx) proposes an invalid screen.
function play.route(input, ctx)
    if input.key == "z" then
        ctx:create()

        return {
            action = "screen",
            screen = "invalid",
            returnable = false,
        }
    end

    return {
        action = "none",
    }
end

return play
