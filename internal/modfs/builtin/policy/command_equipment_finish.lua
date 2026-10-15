local equipment = require("policy.inventory.equipment")
local finish = {}

function finish.run(ctx, input)
    local actor = ctx:player()

    if input.delay then
        return { messages = { equipment.start(ctx, actor, input.delay) } }
    end

    if input.kind == 14 then
        return { messages = equipment.advance(ctx, actor) }
    end

    return { messages = {} }
end

register.policy({
    id = "command.equipment_finish",
    run = finish.run,
})

return finish
