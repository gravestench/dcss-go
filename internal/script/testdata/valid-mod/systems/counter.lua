-- The valid system increments its counter through the registered scheduler.
-- Theory of operation: create a missing counter once, then update that saved
-- component on later turns using the mod helper loaded through the VFS.

local increment = require("lib.increment")

register.system{
    id = "test.count_turns",
    -- Branch on component presence so both add and set paths of the sandbox
    -- bridge are exercised over successive updates.
    update = function(ctx, entity)
        local counter = ctx:get(entity, "test.counter")

        if counter == nil then
            ctx:add(entity, "test.counter", { value = increment(0) })
            return
        end

        ctx:set(entity, "test.counter", {
            value = increment(counter.value),
        })
    end,
}
