local acrobat = require("policy.jewellery.acrobat")
local signals = require("constants.world_signals")
local component = require("constants.component")
local followers = require("policy.world.stair_followers")

local action = {}

-- Command preparation is read-only. This hook runs after the engine opens
-- the accepted action, so component changes survive the action boundary.
-- Example: action.run(ctx, { waited_explicitly = true }) updates Acrobat status before command resolution.
function action.run(ctx, input)
    acrobat.begin_action(ctx, ctx:player(),
        input.waited_explicitly == true)

    -- Portal travel uses a generic WAIT intent until its staged destination
    -- commits. Mark that accepted action so a timed gate under the player
    -- cannot close during the same turn and invalidate the travel plan.
    if input.portal_travel == true then
        ctx:signal(signals.PORTAL_TRAVEL, ctx:player())
    end

    -- The destination has been validated by Go before this accepted
    -- action. Tag before monster decisions can scatter the wave; the
    -- arrival owner checks whether the destination admits followers.
    if input.stair_travel == true or input.portal_travel == true then
        local player = ctx:player()
        local origin = ctx:get(player, component.POSITION)

        followers.tag(ctx, player, origin, input.portal_travel == true)
    end

    return {}
end

register.policy({
    id = "command.action_start",
    run = action.run,
})

return action
