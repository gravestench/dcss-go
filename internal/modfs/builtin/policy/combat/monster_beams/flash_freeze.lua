local component = require("constants.component")
local senses = require("policy.character.senses")

local flash_freeze = {}

-- Example: flash_freeze.skip_damage(ctx, defender) with already frozen defender -> true to skip repeat base damage
-- A second contact cannot damage or refresh a defender already encased by Flash Freeze.
function flash_freeze.skip_damage(ctx, defender)
    return ctx:has(defender, component.FLASH_FROZEN)
end

-- beam.cc:bolt::affect_{player,monster} does not refresh an existing
-- encasement. The first contact adds source-duration ice after the hit.
function flash_freeze.after_hit(ctx, _, defender)
    if ctx:has(defender, component.FLASH_FROZEN) then
        return
    end

    local duration

    if ctx:has(defender, component.PLAYER) then
        duration = 20 + 10 * ctx:random("monster_spell", 3)
        ctx:emit("combat", "You are encased in ice.")
    else
        local actor = ctx:get(defender, component.ACTOR)

        duration = math.max(1,
            math.floor(300 / math.max(1, actor.speed)))
        if senses.player_sees_actor(ctx, defender) then
            ctx:emit("combat", "The monster is flash-frozen.")
        end
    end

    ctx:add(defender, component.FLASH_FROZEN, {
        remaining_aut = duration,
    })
end

return flash_freeze
