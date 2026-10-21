-- The kernel asks this one Lua policy whether play has ended. The state and
-- its win condition remain in the player chapter, not in a Go rules switch.
local endgame = require("policy.character.endgame")
local phases = require("constants.endgame")

local outcome = {}

-- Return only terminal outcomes. Exploration and the Orb run remain active.
function outcome.run(ctx)
    local phase = endgame.phase(ctx, ctx:player())

    if phase == phases.WON or phase == phases.LEFT then
        return {
            kind = phase,
        }
    end

    return {
        kind = "",
    }
end

register.policy({
    id = "session.outcome",
    run = outcome.run,
})

return outcome
