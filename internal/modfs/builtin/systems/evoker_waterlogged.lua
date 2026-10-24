-- The wave's waterlogging expires on the active floor before monster AI
-- selects a spell. The saved component is the sole timer authority.
local component = require("constants.component")
local catalog = require("policy.catalog")
local senses = require("policy.character.senses")

local system = {}

-- End the vocal restriction at zero, preserving the source expiry notice.
function system.update(ctx, monster, aut)
    local state = ctx:get(monster, component.MONSTER_WATERLOGGED)

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(monster, component.MONSTER_WATERLOGGED)

        if senses.player_sees_actor(ctx, monster) then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)

            ctx:emit("combat", "The " .. definition.name ..
                " is no longer waterlogged.")
        end
    else
        ctx:set(monster, component.MONSTER_WATERLOGGED, state)
    end
end

register.system({
    id = "evoker.waterlogged.tick",
    scope = "active",
    query = { component.MONSTER_WATERLOGGED },
    before = { "monster.decision" },
    update = system.update,
})

return system
