-- Source: traps.cc. The alarm is destroyed after its first trigger.
local mark = require("policy.traps.mark")
local noise = require("policy.world.noise")

local effect = {}

-- Feed a loud noise field from the trap cell so waking and mark effects share one source.
-- Example: effect.trigger(ctx, nil, player, site) marks the player and emits alarm noise.
function effect.trigger(ctx, _, actor, site)
    if actor == ctx:player() then
        ctx:emit("trap", "You set off the alarm!")
    else
        ctx:emit("trap", "A monster sets off the alarm!")
    end

    local origin = {
        level_id = site.level_id,
        x = site.x,
        y = site.y,
    }
    local volume = noise.emit(ctx, origin, 40, actor)

    if volume == 0 then
        ctx:emit("trap", "The alarm vibrates slightly, failing to make a sound.")
    else
        ctx:emit("trap", "The alarm emits a blaring wail!")
    end

    mark.apply(ctx, ctx:player())

    return true
end

return effect
