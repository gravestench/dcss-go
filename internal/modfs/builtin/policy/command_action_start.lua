local acrobat = require("policy.jewellery.acrobat")

local action = {}

-- Command preparation is read-only. This hook runs after the engine opens
-- the accepted action, so component changes survive the action boundary.
-- Example: action.run(ctx, { waited_explicitly = true }) updates Acrobat status before command resolution.
function action.run(ctx, input)
    acrobat.begin_action(ctx, ctx:player(),
        input.waited_explicitly == true)

    return {}
end

register.policy({
    id = "command.action_start",
    run = action.run,
})

return action
