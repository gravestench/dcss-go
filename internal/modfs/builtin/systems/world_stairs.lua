local abyss = require("policy.world.abyss")

local system = {}

function system.update(ctx, actor)
    local intent = ctx:get(actor, "core.intent")

    if not intent or (intent.kind ~= 4 and intent.kind ~= 5) then
        return
    end

    local position = ctx:get(actor, "core.position")

    if not position then
        error("stair actor " .. ctx:id(actor) .. " has no position")
    end

    local glyph = intent.kind == 4 and "DNGN_STONE_STAIRS_UP_I" or
        "DNGN_STONE_STAIRS_DOWN_I"

    if ctx:cell(position.level_id, position.x, position.y) ~= glyph then
        error("stair actor " .. ctx:id(actor) .. " is not on a stair")
    end

    if position.level_id == abyss.level_id then
        if glyph ~= "DNGN_STONE_STAIRS_UP_I" or actor ~= ctx:player() then
            error("only the player can use an Abyss exit")
        end

        abyss.escape(ctx, actor)

        return
    end

    local link = ctx:stair_at(position.level_id, position.x, position.y)

    if not link or link.unavailable ~= "" then
        error("stair actor " .. ctx:id(actor) .. " has no available stair link")
    end

    ctx:move_actor(actor, link.to_level_id, link.to_x, link.to_y)
    ctx:emit("stairs", "You take the stairs.")
end

register.system({
    id = "world.stairs",
    scope = "active",
    query = {},
    after = { "monster.decision" },
    before = { "item.pickup" },
    update = system.update,
})

return system
