local items = require("policy.inventory.items")
local doors = require("policy.inventory.doors")

register.system({
    id = "world.doors",
    scope = "active",
    query = {},
    after = { "item.quaff" },
    update = function(ctx, actor)
        local intent = ctx:get(actor, "core.intent")

        if not intent or (intent.kind ~= 8 and intent.kind ~= 9) then
            return
        end

        local position = ctx:get(actor, "core.position")

        if not position then
            error("door actor " .. ctx:id(actor) .. " has no position")
        end

        local level = position.level_id
        local x = position.x + intent.dx
        local y = position.y + intent.dy

        if intent.kind == 8 then
            for _, cell in ipairs(doors.group(ctx, level, x, y, "+")) do
                ctx:set_cell(level, cell.x, cell.y, "'")
            end

            ctx:emit("door", "You open the door.")

            return
        end

        local group = doors.group(ctx, level, x, y, "'")

        for _, cell in ipairs(group) do
            if ctx:actor_at(level, cell.x, cell.y) then
                ctx:emit("door", "Something is blocking the doorway!")

                return
            end
        end

        local excluded = doors.excluded(group)
        local moved = false

        for _, cell in ipairs(group) do
            local floor = items.at(ctx, { level_id = level, x = cell.x, y = cell.y })
            local targets = doors.push_targets(ctx, level, cell, excluded)

            if #floor > 0 and #targets == 0 then
                error("door became jammed after command preparation")
            end

            for _, entity in ipairs(floor) do
                local choice = #targets == 1 and 1 or ctx:random("door", #targets) + 1
                local location = ctx:get(entity, "core.position")
                location.x = targets[choice].x
                location.y = targets[choice].y
                ctx:set(entity, "core.position", location)
                moved = true
            end
        end

        for _, cell in ipairs(group) do
            ctx:set_cell(level, cell.x, cell.y, "+")
        end

        if moved then
            ctx:emit("door", "You close the door, pushing everything out of the way.")
        else
            ctx:emit("door", "You close the door.")
        end
    end,
})
