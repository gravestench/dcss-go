-- Zin removes acquired good mutations or recites disabling law. Every
-- successful effect writes through an existing saved mutation/status owner.
local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local choices = require("constants.mutation_choices")
local noise = require("policy.world.noise")
local paralysis = require("policy.character.paralysis")
local physiology = require("policy.mutations.physiology")
local records = require("policy.mutations.records")
local sleep = require("policy.combat.monster_beams.sleep")
local streams = require("constants.rng_streams")
local transition = require("policy.mutations.transition")

local zin = {}

-- player::how_mutated counts noninnate mutation types, including temporary
-- ranks; a body without them skips Zin's first two punishment slots.
local function mutated(ctx, player)
    for _, entry in ipairs(records.list(ctx, player)) do
        if entry.state.acquired + entry.state.temporary > 0 then
            return true
        end
    end

    return false
end

-- Source binomial(7, 75, 100) is seven independent percentage trials.
-- The C++ inclusive loop attempts one more deletion than that result.
local function remove_good(ctx, player)
    ctx:emit("religion", "Zin draws some chaos from your body!")

    local count = 0

    for _ = 1, 7 do
        if ctx:random(streams.CARDS, 100) < 75 then
            count = count + 1
        end
    end

    local removed = false

    for _ = 0, count do
        -- god_gift skips mutation resistance, but force_mutation=false
        -- still checks whether this body can safely mutate.
        if physiology.can_safely_mutate(ctx, player) then
            local result = transition.remove_random(ctx, player,
                choices.GOOD, true)

            if result.kind == "removed" then
                removed = true
            end
        end
    end

    if removed and not mutated(ctx, player) then
        ctx:emit("religion", "Zin rids your body of chaos!")
    end

    return removed
end

-- The recital's three equal choices use saved Confusion, Sleep and
-- Paralysis. Paralysis suppresses later bonus debilitation in the caller.
local function recital(ctx, player)
    ctx:emit("religion", "Zin recites the Axioms of Law to you!")

    local choice = ctx:random(streams.CARDS, 3)

    if choice == 0 then
        confusion.extend(ctx, player,
            5 + ctx:random(streams.CARDS, 3))
    elseif choice == 1 then
        sleep.apply_unresisted(ctx, player,
            30 + ctx:random(streams.CARDS, 20))
    else
        paralysis.divine(ctx, player, streams.CARDS)

        return false
    end

    return true
end

-- Failed good-mutation removal falls through to recital without another
-- punishment draw; unmutated players sample only the final four slots.
function zin.apply(ctx, player)
    local has_mutation = mutated(ctx, player)
    local choice = has_mutation and
        ctx:random(streams.CARDS, 6) or
        2 + ctx:random(streams.CARDS, 4)

    if choice < 2 then
        if remove_good(ctx, player) then
            return true
        end

        return recital(ctx, player)
    end

    if choice < 5 then
        return recital(ctx, player)
    end

    ctx:emit("religion", 'Zin booms out: "Turn to the light! REPENT!"')
    noise.emit(ctx, ctx:get(player, component.POSITION), 25, player)

    return true
end

return zin
