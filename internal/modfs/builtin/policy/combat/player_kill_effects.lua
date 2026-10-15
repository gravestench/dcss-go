local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local levels = require("policy.mutations.levels")

local effects = {}
local handlers = {}

function effects.add(mutation_id, handler)
    catalog.get(categories.MUTATIONS, mutation_id)

    if type(handler) ~= "function" or handlers[mutation_id] then
        error("duplicate or invalid player kill effect " .. mutation_id)
    end

    handlers[mutation_id] = handler
end

function effects.has_mutation(mutation_id)
    return handlers[mutation_id] ~= nil
end

-- Kill effects run after XP eligibility is determined. They read the same
-- effective mutation levels as combat, spells, and regeneration.
function effects.run(ctx, player, monster, xp)
    if xp <= 0 then
        return
    end

    local ids = {}

    for mutation_id in pairs(handlers) do
        ids[#ids + 1] = mutation_id
    end

    table.sort(ids)

    for _, mutation_id in ipairs(ids) do
        local level = levels.effective(ctx, player, mutation_id)

        if level > 0 then
            handlers[mutation_id](ctx, player, monster, level)
        end
    end
end

return effects
