local capabilities = require("constants.mutation_capabilities")
local classes = require("constants.mutation_classes")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local resistance = {}

-- Expose the effective resistance level to both mutation gain and deletion
-- gates, so suppression changes both decisions together.
function resistance.level(level)
    return level
end

registry.add(mutations.MUT_MUTATION_RESISTANCE, {
    [capabilities.MUTATION_RESISTANCE] = resistance.level,
})

-- Source: mutation.cc:_resist_mutation. The third level always blocks;
-- lower levels block unless the saved mutation stream draws zero.
-- Example: mutation resistance level three always blocks an intrinsic mutation attempt.
function resistance.intrinsic_blocks(ctx, owner, class)
    local level = registry.sum(ctx, owner,
        capabilities.MUTATION_RESISTANCE)

    if level >= 3 then
        return true
    end

    if level == 0 then
        return false
    end

    local chance = class == classes.TEMPORARY and 2 or 3

    return ctx:random("mutation", chance) ~= 0
end

-- Source: mutation.cc:delete_mutation protects acquired levels only when
-- intrinsic mutation resistance is above level one.
function resistance.deletion_blocks(ctx, owner)
    local level = registry.sum(ctx, owner,
        capabilities.MUTATION_RESISTANCE)

    if level >= 3 then
        return true
    end

    return level == 2 and ctx:random("mutation", 2) == 0
end

return resistance
