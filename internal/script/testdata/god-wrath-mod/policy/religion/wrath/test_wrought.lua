-- A modded punishment writes an ordinary saved worship field. This proves
-- the effective handler, rather than a test-only callback, was dispatched.
local component = require("constants.component")

local wrought = {}

-- The fixture uses a harmless state change to make selection observable.
function wrought.apply(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.gift_timeout = 17
    ctx:set(player, component.RELIGION_WORSHIP, state)

    return true
end

return wrought
