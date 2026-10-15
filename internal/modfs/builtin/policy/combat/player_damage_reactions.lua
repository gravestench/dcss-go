local reactions = {}
local entries = {}
local before_entries = {}
local after_by_id = {}
local before_by_id = {}

local function ordered(left, right)
    if left.order ~= right.order then
        return left.order < right.order
    end

    return left.id < right.id
end

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

function reactions.add(id, order, on_damage)
    add(entries, after_by_id, id, order, on_damage)
end

function reactions.add_before(id, order, on_damage)
    add(before_entries, before_by_id, id, order, on_damage)
end

function reactions.has_mutation(mutation_id)
    return after_by_id[mutation_id] == true or
        before_by_id[mutation_id] == true
end

function reactions.before_hp(ctx, player, damage)
    if damage <= 0 then
        return
    end

    for _, entry in ipairs(before_entries) do
        entry.on_damage(ctx, player, damage)
    end
end

function reactions.after_hp(ctx, player, damage, cause)
    if damage <= 0 then
        return
    end

    for _, entry in ipairs(entries) do
        entry.on_damage(ctx, player, damage, cause)
    end
end

return reactions
