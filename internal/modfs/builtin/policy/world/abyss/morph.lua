-- Theory of operation: Abyss branch depth is a travel depth, while
-- morph depth is a separate source sampling clock. A completed player
-- action advances that clock and resamples only queue entries whose
-- change point has passed. Authored cells and exits never decay.
local abyss = require("constants.abyss")
local sampler = require("policy.generation.abyss.sampler")
local terrain = require("constants.terrain")

local morph = {}

local permanent = {
    [terrain.DNGN_EXIT_ABYSS] = true,
    [terrain.DNGN_ABYSSAL_STAIR] = true,
    [terrain.DNGN_RUNELIGHT] = true,
    [terrain.DNGN_RANDOM_ALTAR] = true,
    [terrain.DNGN_ALTAR_LUGONU] = true,
}

-- Source _increase_depth converts a floating change to uint32 after
-- adding it to the integer clock. This keeps the truncated increment
-- while phase remains fractional for the next turn's sinusoidal rate.
local function advance_clock(state, elapsed_aut)
    local delta = math.floor(elapsed_aut * abyss.MORPH_SPEED_BONUS /
        abyss.MORPH_SPEED_DIVISOR) * abyss.MORPH_DEFAULT_MULTIPLIER
    local theta = state.phase
    local rate = abyss.MORPH_BASE_RATE + abyss.MORPH_WAVE_RATE *
        math.sin(theta / 2) ^ abyss.MORPH_WAVE_POWER

    state.morph_depth = math.floor(state.morph_depth + delta * rate)
    state.phase = state.phase + delta / abyss.MORPH_PHASE_DIVISOR

    if state.phase > math.pi then
        state.phase = state.phase - math.pi
    end
end

-- A record at a coordinate belongs to an authored vault. Source morph
-- skips those cells so terrain and pending item or monster instructions
-- do not separate from their map during ordinary passage of time.
local function authored(ctx, x, y)
    for _, record in ipairs(ctx:records_at(abyss.LEVEL_ID, x, y)) do
        if not record.overridden and
            (record.vault_id or record.source_id) then
            return true
        end
    end

    return false
end

-- Sorting after changed entries are requeued preserves deterministic
-- replay independent of Lua table iteration and source queue order.
local function earlier(left, right)
    if left.change ~= right.change then
        return left.change < right.change
    end

    if left.y ~= right.y then
        return left.y < right.y
    end

    return left.x < right.x
end

-- The context has the staged actor view. A new solid feature never
-- traps an actor; its cell is kept and reconsidered at the next sample
-- change point. The player also keeps safe footing over lava and water.
local function safe_feature(ctx, sample, next_feature, player)
    local actor = ctx:actor_at(abyss.LEVEL_ID,
        sample.x, sample.y)

    if not actor then
        return next_feature
    end

    if actor == player then
        if next_feature == terrain.DNGN_DEEP_WATER then
            return terrain.DNGN_SHALLOW_WATER
        end

        if next_feature == terrain.DNGN_LAVA or
            next_feature == terrain.DNGN_ROCK_WALL then
            return terrain.DNGN_FLOOR
        end
    end

    if next_feature ~= terrain.DNGN_FLOOR and
        next_feature ~= terrain.DNGN_SHALLOW_WATER then
        return ctx:cell(abyss.LEVEL_ID, sample.x, sample.y)
    end

    return next_feature
end

-- Consume each expired queue entry once. The returned state is detached
-- from the session record until replace_session_state commits it after
-- the staged terrain edits have passed validation.
function morph.advance(ctx, state, player, elapsed_aut)
    advance_clock(state, elapsed_aut)

    local next_queue = {}

    for _, sample in ipairs(state.sample_queue) do
        if sample.change >= state.morph_depth then
            next_queue[#next_queue + 1] = sample
        else
            local current = ctx:cell(abyss.LEVEL_ID,
                sample.x, sample.y)

            if not permanent[current] and
                not authored(ctx, sample.x, sample.y) then
                local feature, change = sampler.sample(ctx, state,
                    sample.x, sample.y)
                local safe = safe_feature(ctx, sample,
                    feature, player)

                if safe ~= current then
                    ctx:set_cell(abyss.LEVEL_ID,
                        sample.x, sample.y, safe)
                end

                next_queue[#next_queue + 1] = {
                    x = sample.x,
                    y = sample.y,
                    change = change,
                    feature = feature,
                }
            end
        end
    end

    table.sort(next_queue, earlier)
    state.sample_queue = next_queue

    return state
end

return morph
