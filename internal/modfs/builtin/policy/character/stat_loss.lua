-- Example: A temporary Strength drain changes current Strength without editing its base value.
local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local stats = require("constants.stats")
local mutation_effects = require("policy.mutations.effects.registry")

local stat_loss = {}

local stat_capability = {
    [stats.STRENGTH] = capabilities.STRENGTH,
    [stats.INTELLIGENCE] = capabilities.INTELLIGENCE,
    [stats.DEXTERITY] = capabilities.DEXTERITY,
}

-- Read one stat drain independently of permanent base attributes.
function stat_loss.amount(ctx, owner, field)
    local loss = ctx:get(owner, component.STAT_LOSS)

    return loss and loss[field] or 0
end

-- Source: player-stats.cc:lose_stat chooses a stat before the first
-- recovery roll. Later drains retain the current recovery countdown.
function stat_loss.drain(ctx, owner, field, amount)
    if not stat_capability[field] or amount < 1 then
        error("invalid attribute drain")
    end

    local loss = ctx:get(owner, component.STAT_LOSS)
    local created = not loss

    if created then
        loss = {
            strength = 0,
            intelligence = 0,
            dexterity = 0,
            remaining_xp = 0,
        }
    end

    loss[field] = math.min(100, loss[field] + amount)

    if loss.remaining_xp == 0 then
        loss.remaining_xp = 30 + ctx:random("mutation", 30)
    end

    if created then
        ctx:add(owner, component.STAT_LOSS, loss)
    else
        ctx:set(owner, component.STAT_LOSS, loss)
    end

    return field
end

-- Use the mutation stream to choose the drained stat before changing its recovery timer.
function stat_loss.drain_random(ctx, owner)
    local index = ctx:random("mutation", #stats.ORDER) + 1

    return stat_loss.drain(ctx, owner, stats.ORDER[index], 1)
end

-- Pick among currently drained stats only when an XP recovery point comes due.
local function choose_drained(ctx, loss)
    local chosen
    local seen = 0

    for _, field in ipairs(stats.ORDER) do
        if loss[field] > 0 then
            seen = seen + 1

            if ctx:random("mutation", seen) == 0 then
                chosen = field
            end
        end
    end

    return chosen
end

-- Keep the shared XP recovery timer while any stat still has temporary loss.
local function remaining_after(loss, recovered)
    for _, field in ipairs(stats.ORDER) do
        if loss[field] - recovered[field] > 0 then
            return true
        end
    end

    return false
end

-- A severely drained current stat can increase the recovered amount.
local function raw_stat(ctx, owner, loss, field)
    local base = ctx:get(owner, component.ATTRIBUTES)

    if not base then
        error("stat recovery requires player attributes")
    end

    local maximum = math.min(125,
        base[field] + mutation_effects.base_sum(ctx, owner,
            stat_capability[field]))

    return maximum - loss[field]
end

-- Source: player.cc:_handle_stat_loss and _recover_stat. Skill cost comes
-- from the same progression value used by the training system.
-- Experience pays down drain one point at a time and may grant a larger recovery for severe stat loss.
function stat_loss.gain_experience(ctx, owner, xp, cost_level)
    local loss = ctx:get(owner, component.STAT_LOSS)

    if not loss or loss.remaining_xp <= 0 or xp <= 0 then
        return 0
    end

    local formulas = require("policy.character.formulas")
    local divisor = math.max(1,
        formulas.skill_point_cost(cost_level) - 3)
    local numerator = math.floor(xp * 3 / 2)
    local progress = math.floor(numerator / divisor)
    local remainder = numerator % divisor

    if remainder > 0 and ctx:random("mutation", divisor) < remainder then
        progress = progress + 1
    end

    loss.remaining_xp = loss.remaining_xp - progress

    if loss.remaining_xp > 0 then
        ctx:set(owner, component.STAT_LOSS, loss)

        return 0
    end

    local recovered = {
        strength = 0,
        intelligence = 0,
        dexterity = 0,
    }

    while loss.remaining_xp <= 0 do
        local field = choose_drained(ctx, loss)

        if not field then
            error("stat recovery has no drained attribute")
        end

        recovered[field] = recovered[field] + 1

        local current = raw_stat(ctx, owner, loss, field)

        if current < 0 then
            local bonus_bound = math.floor(-current / 2)

            if bonus_bound > 1 then
                recovered[field] = recovered[field] +
                    ctx:random("mutation", bonus_bound)
            end
        end

        if remaining_after(loss, recovered) then
            loss.remaining_xp = loss.remaining_xp +
                30 + ctx:random("mutation", 30)
        else
            loss.remaining_xp = 0
            break
        end
    end

    local total = 0

    for _, field in ipairs(stats.ORDER) do
        if recovered[field] > 0 then
            loss[field] = math.max(0, loss[field] - recovered[field])
            total = total + recovered[field]
            ctx:emit("recovery", "You feel your " .. field .. " returning.")
        end
    end

    ctx:set(owner, component.STAT_LOSS, loss)

    return total
end

return stat_loss
