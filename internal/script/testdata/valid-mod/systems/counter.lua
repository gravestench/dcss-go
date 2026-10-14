local increment = require("lib.increment")

register.system{
    id = "test.count_turns",
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
