local component = require("constants.component")
local fillings = require("constants.pie_fillings")
local statuses = require("policy.magic.effects.statuses.player")
local senses = require("policy.character.senses")

local blueberry = {
    id = fillings.BLUEBERRY,
    weight = 10,
}

-- Example: blueberry.valid() with any pie target -> true eligibility
-- Blueberry filling has no target restriction, so it remains in every pie selection pool.
function blueberry.valid()
    return true
end

-- Blueberry silences players but stores a monster mute duration for non-player targets.
function blueberry.apply(ctx, _, target)
    if ctx:has(target, component.PLAYER) then
        statuses.add_silence(ctx, target,
            4 + ctx:random("monster_spell", 7), 10)
        ctx:emit("combat", "An unnatural silence engulfs you.")

        return
    end

    local state = ctx:get(target, component.MONSTER_MUTE)
    local added = 4 + 10 * ctx:random("monster_spell", 7)

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(target, component.MONSTER_MUTE, state)
    else
        ctx:add(target, component.MONSTER_MUTE, {
            remaining_aut = added,
        })
    end

    if senses.player_sees_actor(ctx, target) then
        ctx:emit("combat", "The monster loses the ability to speak.")
    end
end

return blueberry
