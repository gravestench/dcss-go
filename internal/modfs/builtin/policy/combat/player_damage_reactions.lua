local reactions = {}
local entries = {}
local before_entries = {}
local after_by_id = {}
local before_by_id = {}

-- Tie-break reaction order by id so equal-priority callbacks remain deterministic.
local function ordered(left, right)
    if left.order ~= right.order then
        return left.order < right.order
    end

    return left.id < right.id
end

-- Keep reaction IDs unique and sort callbacks so registration order cannot change damage handling.
local function add(target, by_id, id, order, on_damage)
    if by_id[id] then
        error("duplicate player damage reaction " .. tostring(id))
    end

    if type(order) ~= "number" or type(on_damage) ~= "function" then
        error("invalid player damage reaction " .. tostring(id))
    end

    by_id[id] = true
    target[#target + 1] = {
        id = id,
        order = order,
        on_damage = on_damage,
    }

    table.sort(target, ordered)
end

-- Example: reactions.add(id, order, on_damage) with duplicate reaction ID -> registration error
-- Register an after-HP callback with stable priority so mutation load order cannot change damage reactions.
function reactions.add(id, order, on_damage)
    add(entries, after_by_id, id, order, on_damage)
end

-- Install a callback that observes positive incoming damage before HP changes.
function reactions.add_before(id, order, on_damage)
    add(before_entries, before_by_id, id, order, on_damage)
end

-- Report whether a mutation contributes either before- or after-HP damage behavior.
function reactions.has_mutation(mutation_id)
    return after_by_id[mutation_id] == true or
        before_by_id[mutation_id] == true
end

-- Before-HP callbacks see positive incoming damage before health is changed.
function reactions.before_hp(ctx, player, damage)
    if damage <= 0 then
        return
    end

    for _, entry in ipairs(before_entries) do
        entry.on_damage(ctx, player, damage)
    end
end

-- After-HP callbacks receive the final cause for mutation and retaliation effects.
function reactions.after_hp(ctx, player, damage, cause, attacker)
    if damage <= 0 then
        return
    end

    for _, entry in ipairs(entries) do
        entry.on_damage(ctx, player, damage, cause, attacker)
    end
end

return reactions
