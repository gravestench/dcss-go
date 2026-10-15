local cast = require("policy.magic.cast")
local channel = require("policy.magic.channel")

local player_spell = {}

function player_spell.update(ctx, actor, aut)
    if actor ~= ctx:player() then
        return
    end

    local intent = ctx:get(actor, "core.intent")

    if intent and intent.kind == 15 then
        channel.cancel(ctx, actor)
        local result = cast.resolve(ctx, actor, intent, aut)

        if result == "success" then
            channel.cast_finished(ctx, actor)
            ctx:signal("player_spell_success", actor)
        end
    elseif intent and intent.kind == 16 then
        channel.wait(ctx, actor, aut)
    else
        channel.cancel(ctx, actor)
    end
end

register.system({
    id = "attack.player_spell",
    scope = "active",
    query = {},
    after = { "attack.spell" },
    before = { "world.movement" },
    update = player_spell.update,
})

return player_spell
