-- Theory of operation: source DCSS asks twice before excommunication. Each
-- free prompt carries the current god ID, so an answer cannot apply after
-- another action changes worship. The final timed ability uses the same
-- leave path as altar conversion and retains saved penance for later wrath.
local abilities = require("ids.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local worship = require("policy.religion.worship")

local renounce = {}
local first = "renounce_first:"
local second = "renounce_second:"

-- A godless player has no faith to renounce. The menu queries the live ECS
-- owner, so conversion immediately adds this ability without rebuilding it.
function renounce.available(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    return state ~= nil and state.god_id ~= gods.NO_GOD
end

-- Return two distinct confirmations before the generic ability command
-- spends a turn. The IDs bind both prompts to the same current patron.
function renounce.prepare(ctx, player, input)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id == gods.NO_GOD then
        return "You do not worship a god."
    end

    local god_id = state.god_id

    if not input.forced or input.target_id == "" then
        return {
            confirmation = "Really renounce your faith, foregoing its fabulous benefits?",
            confirmation_id = first .. god_id,
        }
    end

    if input.target_id == first .. god_id then
        return {
            confirmation = "Are you sure?",
            confirmation_id = second .. god_id,
        }
    end

    if input.target_id ~= second .. god_id then
        return "Your faith changed before you answered."
    end

    -- Renouncing Okawaru inside a Duel is a forced return. Prepare the
    -- destination now so an impossible landing cannot strand the player
    -- after excommunication has already been committed.
    if god_id == gods.OKAWARU and
        ctx:has(player, component.PLAYER_ARENA_VISIT) then
        return require("policy.world.arena.travel")
            .prepare_forced(ctx, player)
    end

    return nil
end

-- Excommunication is the common transition, including per-god leave hooks
-- and penance; the ability adds only its source-facing event text.
function renounce.resolve(ctx, player)
    if not worship.renounce(ctx, player) then
        error("renunciation resolved after worship ended")
    end

    ctx:emit("religion", "You have renounced your religion.")
end

registry.add(abilities.RENOUNCE_RELIGION, {
    name = "Renounce Religion",
    available = renounce.available,
    prepare = renounce.prepare,
    resolve = renounce.resolve,
})

return renounce
