-- Okawaru's saved combat clocks age on player time before the next
-- command reads skill and attack speed. The patron owns no Go timer.
local component = require("constants.component")
local status = require("policy.religion.okawaru.status")

local system = {}

-- Only the player can carry these boons; the save validator enforces it.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        status.tick(ctx, player, aut)
    end
end

register.system({
    id = "religion.okawaru_status.tick",
    scope = "active",
    query = { component.RELIGION_OKAWARU_STATUS },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
