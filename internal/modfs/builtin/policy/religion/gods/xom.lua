-- Xom's ecumenical reward is stimulation, not a piety gain. Save it for
-- the later Xom mood owner instead of replacing it with a generic bonus.
local component = require("constants.component")

local xom = {}

-- Record the source stimulation amount for later resolution.
function xom.ecumenical_bonus(ctx, player)
    local state = ctx:get(player, component.RELIGION_XOM)

    if state then
        state.pending_stimulation = state.pending_stimulation + 200
        ctx:set(player, component.RELIGION_XOM, state)
    else
        ctx:add(player, component.RELIGION_XOM, {
            pending_stimulation = 200,
        })
    end
end

return xom
