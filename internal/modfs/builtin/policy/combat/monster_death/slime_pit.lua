-- Theory of operation: the source Royal Jelly carries a death callback.
-- Its original vault identity, saved on the actor, releases the Slime Pit
-- clear stone walls even if the monster moved or changed shape first.
local channels = require("constants.message_channels")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")
local names = require("constants.slime_pit")
local terrain = require("constants.terrain")

local slime_pit = {}

-- One original monster can release each cell only once. Keep marker
-- entities after the wall falls so the event remains auditable in saves.
function slime_pit.on_death(ctx, monster)
    local origin = ctx:get(monster, component.VAULT_ORIGIN)

    if not origin or origin.vault_id ~= names.MAP_ID or
        origin.kind_id ~= monsters.MONS_ROYAL_JELLY or
        origin.occurrence ~= 1 then
        return false
    end

    local found = 0
    local released = 0

    for _, entity in ipairs(ctx:query({ component.SLIME_SEAL })) do
        local state = ctx:get(entity, component.SLIME_SEAL)

        if state.level_id == origin.level_id then
            found = found + 1

            if not state.released then
                if ctx:cell(state.level_id, state.x, state.y) ==
                    terrain.DNGN_CLEAR_STONE_WALL then
                    ctx:set_cell(state.level_id, state.x, state.y,
                        terrain.DNGN_FLOOR)
                end

                state.released = true
                ctx:set(entity, component.SLIME_SEAL, state)
                released = released + 1
            end
        end
    end

    if found == 0 then
        error("the Royal Jelly has no saved Slime Pit seal")
    end

    if released > 0 then
        ctx:emit(channels.MONSTER,
            "The stone walls suddenly crumble and collapse.")
    end

    return false
end

death_hooks.add("slime_pit.royal_jelly", slime_pit.on_death)

return slime_pit
