local catalog = require("policy.catalog")
local classes = require("constants.mutation_classes")
local records = require("policy.mutations.records")
local transition = require("policy.mutations.transition")

local temporary = {}

-- Source: mutation.cc:temp_mutation_roll. The source rolls five dice and
-- scales their sum by the current experience level, capped at XL17.
function temporary.roll(ctx, owner)
    local progress = ctx:get(owner, "core.progression")

    if not progress or progress.level < 1 then
        error("temporary mutation roll requires player experience level")
    end

    local dice = 500

    for _ = 1, 5 do
        dice = dice + ctx:random("mutation", 500) + 1
    end

    return math.floor(math.min(progress.level, 17) * dice / 17)
end

-- Example: two temporary mutation IDs have equal expiry chance even when one holds more ranks.
-- Source: mutation.cc:delete_temp_mutation uses reservoir selection over
-- mutation IDs, so each ID is equally likely even if it has several levels.
function temporary.choose_expiring(ctx, owner)
    local chosen
    local count = 0

    for _, definition in ipairs(catalog.all("mutations")) do
        local entry = records.find(ctx, owner, definition.id)

        if entry and entry.state.temporary > 0 then
            count = count + 1

            if ctx:random("mutation", count) == 0 then
                chosen = definition.id
            end
        end
    end

    if not chosen then
        error("temporary mutation expiry found no mutation")
    end

    return chosen
end

-- Source: mutation.cc:temp_mutation_wanes. A single XP threshold can remove
-- several temporary levels, then adds one fresh roll to any XP overshoot.
function temporary.wane(ctx, owner)
    local starting = records.temporary_count(ctx, owner)

    if starting == 0 then
        return 0
    end

    local scaled = math.floor(starting * 5 / 12) -
        ctx:random("mutation", 3)
    local minimum = 1 + ctx:random("mutation", 3)
    local removing = math.min(starting, math.max(scaled, minimum))
    local extent = removing == starting and "completely" or "somewhat"

    ctx:emit("duration", "You feel the corruption within you wane " ..
        extent .. ".")

    for _ = 1, removing do
        local mutation_id = temporary.choose_expiring(ctx, owner)
        local result = transition.remove(ctx, owner, mutation_id,
            classes.TEMPORARY)

        if result.kind ~= "removed" then
            error("temporary mutation expiry could not remove " .. mutation_id)
        end
    end

    if records.temporary_count(ctx, owner) > 0 then
        local timer = records.timer(ctx, owner)

        records.set_timer(ctx, owner,
            timer.remaining_xp + temporary.roll(ctx, owner))
    else
        records.set_timer(ctx, owner, 0)
    end

    return removing
end

-- Source: player.cc:_handle_temp_mutation applies awarded skill XP once.
function temporary.gain_experience(ctx, owner, amount)
    if type(amount) ~= "number" or amount < 0 or amount % 1 ~= 0 then
        error("temporary mutation XP gain must be nonnegative")
    end

    if records.temporary_count(ctx, owner) == 0 then
        return 0
    end

    local timer = records.timer(ctx, owner)

    if not timer then
        error("temporary mutations lack a shared timer")
    end

    records.set_timer(ctx, owner, timer.remaining_xp - amount)

    if timer.remaining_xp - amount <= 0 then
        return temporary.wane(ctx, owner)
    end

    return 0
end

return temporary
