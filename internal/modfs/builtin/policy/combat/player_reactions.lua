-- Player mutation reactions run at named phases of a monster melee attack.
-- Each reaction registers from its own discoverable Lua file.
local component = require("constants.component")
local levels = require("policy.mutations.levels")

local reactions = {}
local entries = {}
local registered = {}

function reactions.adjacent(ctx, player, monster)
    local left = ctx:get(player, component.POSITION)
    local right = ctx:get(monster, component.POSITION)

    return left and right and left.level_id == right.level_id and
        math.abs(left.x - right.x) <= 1 and
        math.abs(left.y - right.y) <= 1 and
        (left.x ~= right.x or left.y ~= right.y)
end

function reactions.register(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" or
        entry.id == "" or type(entry.order) ~= "number" or
        entry.order % 1 ~= 0 or registered[entry.id] or
        (type(entry.before_contact) ~= "function" and
            type(entry.after_hit) ~= "function" and
            type(entry.after_miss) ~= "function" and
            type(entry.after_attack) ~= "function") then
        error("invalid or duplicate player melee reaction")
    end

    registered[entry.id] = true
    entries[#entries + 1] = entry

    table.sort(entries, function(left, right)
        if left.order == right.order then
            return left.id < right.id
        end

        return left.order < right.order
    end)
end

function reactions.has_mutation(mutation_id)
    return registered[mutation_id] == true
end

local function run(ctx, phase, monster, definition, damage_done)
    local player = ctx:player()

    for _, entry in ipairs(entries) do
        local hook = entry[phase]
        local level = levels.effective(ctx, player, entry.id)

        if hook and level > 0 then
            hook(ctx, player, monster, definition, level, damage_done)
        end

        local health = ctx:get(monster, component.HEALTH)

        if not health or health.current <= 0 then
            return false
        end
    end

    return true
end

function reactions.before_contact(ctx, monster, definition)
    return run(ctx, "before_contact", monster, definition)
end

function reactions.after_hit(ctx, monster, definition, damage_done)
    return run(ctx, "after_hit", monster, definition, damage_done)
end

function reactions.after_miss(ctx, monster, definition)
    return run(ctx, "after_miss", monster, definition)
end

function reactions.after_attack(ctx, monster, definition)
    return run(ctx, "after_attack", monster, definition)
end

return reactions
