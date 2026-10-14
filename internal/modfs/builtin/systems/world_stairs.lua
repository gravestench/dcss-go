register.system({
    id = "world.stairs",
    scope = "active",
    query = {},
    after = { "monster.decision" },
    before = { "item.pickup" },
    update = function(ctx, actor)
        local intent = ctx:get(actor, "core.intent")

        if not intent or (intent.kind ~= 4 and intent.kind ~= 5) then
            return
        end

        local position = ctx:get(actor, "core.position")

        if not position then
            error("stair actor " .. ctx:id(actor) .. " has no position")
        end

        local glyph = intent.kind == 4 and "<" or ">"

        if ctx:cell(position.level_id, position.x, position.y) ~= glyph then
            error("stair actor " .. ctx:id(actor) .. " is not on a stair")
        end

        local link = ctx:stair_at(position.level_id, position.x, position.y)

        if not link or link.unavailable ~= "" then
            error("stair actor " .. ctx:id(actor) .. " has no available stair link")
        end

        ctx:move_actor(actor, link.to_level_id, link.to_x, link.to_y)
        ctx:emit("stairs", "You take the stairs.")
    end,
})
