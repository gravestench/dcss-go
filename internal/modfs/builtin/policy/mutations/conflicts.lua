local classes = require("constants.mutation_classes")
local outcomes = require("constants.mutation_conflict_outcomes")
local rows = require("data.mutation_conflicts")
local records = require("policy.mutations.records")
local effects = require("policy.mutations.effects.registry")
local messages = require("policy.mutations.messages")

local conflicts = {}

local function other_id(row, mutation_id)
    if row.first == mutation_id then
        return row.second
    end

    if row.second == mutation_id then
        return row.first
    end

    return nil
end

local function remove_one(ctx, owner, mutation_id)
    local entry = records.find(ctx, owner, mutation_id)
    local state = entry.state
    local previous = state.innate + state.acquired + state.temporary

    if entry.state.temporary > 0 then
        records.delete(ctx, owner, mutation_id, classes.TEMPORARY, 1)
    else
        records.delete(ctx, owner, mutation_id, classes.ACQUIRED, 1)
    end

    effects.changed(ctx, owner, mutation_id)
    messages.lost(ctx, mutation_id, previous - 1)
end

local function remove_noninnate(ctx, owner, mutation_id)
    local entry = records.find(ctx, owner, mutation_id)

    while entry and entry.state.temporary + entry.state.acquired > 0 do
        remove_one(ctx, owner, mutation_id)
        entry = records.find(ctx, owner, mutation_id)
    end
end

-- The source table is deliberately ordered. An ignore row can be followed
-- by a trade row for the same pair.
function conflicts.resolve(ctx, owner, mutation_id, class, forced)
    for _, row in ipairs(rows) do
        local opposed = other_id(row, mutation_id)
        local entry = opposed and records.find(ctx, owner, opposed) or nil

        if entry then
            local state = entry.state
            local total = state.innate + state.acquired + state.temporary
            local only_innate = state.innate == total

            if state.innate > 0 and
                (row.outcome ~= outcomes.TRADE_ONE or only_innate) then
                return { kind = "blocked", opposed = opposed }
            end

            if row.outcome == outcomes.BLOCK_UNLESS_FORCED and not forced then
                return { kind = "blocked", opposed = opposed }
            end

            if row.outcome == outcomes.IGNORE_UNLESS_FORCED or
                row.outcome == outcomes.BLOCK_UNLESS_FORCED then
                if forced then
                    remove_noninnate(ctx, owner, opposed)
                end
            elseif row.outcome == outcomes.TRADE_ONE then
                local new_temporary = class == classes.TEMPORARY
                local old_temporary = state.temporary > 0

                if new_temporary == old_temporary then
                    remove_one(ctx, owner, opposed)

                    return { kind = "traded", opposed = opposed }
                end
            else
                error("unknown mutation conflict outcome " .. row.outcome)
            end
        end
    end

    return { kind = "continue" }
end

return conflicts
