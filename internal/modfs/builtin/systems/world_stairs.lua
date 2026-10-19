local abyss = require("policy.world.abyss")
local barbs = require("policy.combat.barbs")
local component = require("constants.component")

local system = {}

-- Theory of operation: Travel changes level and position before pickup examines the arrival cell.
-- Stair travel follows monster decisions and precedes item pickup on the destination.
function system.update(ctx, actor, elapsed_aut)
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

    -- Ordinary stair travel counts as a step for player barbs before the
    -- level transition, unlike forced banishment and teleportation.
    if actor == ctx:player() then
        barbs.moved(ctx, actor, elapsed_aut)

        if ctx:get(actor, component.HEALTH).current <= 0 then
            return
        end
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
