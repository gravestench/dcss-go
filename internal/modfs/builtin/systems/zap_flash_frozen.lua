local component = require("constants.component")

local system = {}

-- Theory of operation: The frozen timer is spent before a monster’s next decision, clearing its speed penalty at zero.
-- Flash-frozen duration can clear before the monster chooses an intent.
function system.update(ctx, entity, aut)
    local frozen = ctx:get(entity, component.FLASH_FROZEN)

    if not frozen then
        return
    end

    frozen.remaining_aut = math.max(0, frozen.remaining_aut - aut)

    if frozen.remaining_aut == 0 then
        ctx:remove(entity, component.FLASH_FROZEN)

        if ctx:has(entity, component.PLAYER) then
            ctx:emit("duration", "The ice encasing you melts away.")
        else
            ctx:emit("duration", "The monster is no longer encased in ice.")
        end
    else
        ctx:set(entity, component.FLASH_FROZEN, frozen)
    end
end

register.system({
    id = "zap.flash_frozen.tick",
    scope = "active",
    query = { component.FLASH_FROZEN },
    before = { "monster.decision" },
    update = system.update,
})

return system
