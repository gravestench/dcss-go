local activation = require("policy.traps.activation")
local component = require("constants.component")
local intents = require("constants.intent")
local mark = require("policy.traps.mark")
local malevolence = require("policy.traps.malevolence")
local timer = require("policy.traps.timer")

local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        mark.tick(ctx, actor, aut)
    end

    local intent = ctx:get(actor, component.INTENT)

    if not intent or intent.kind ~= intents.MOVE then
        if actor == ctx:player() then
            timer.tick(ctx, actor, aut)
        end

        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position then
        error("moving actor has no position after movement")
    end

    local previous = {
        level_id = position.level_id,
        x = position.x - intent.dx,
        y = position.y - intent.dy,
    }

    activation.enter(ctx, actor, previous, position)

    if actor == ctx:player() then
        malevolence.roll(ctx, actor)
        timer.tick(ctx, actor, aut)
    end
end

register.system({
    id = "world.traps",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "attack.combat" },
    update = system.update,
})

return system
