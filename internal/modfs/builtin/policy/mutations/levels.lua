local records = require("policy.mutations.records")
local activity = require("policy.mutations.activity")
local activity_levels = require("constants.mutation_activity")

local levels = {}

-- Base, effective, and full levels differ for form suppression and innate mutation checks.
-- Sum the three stored rank classes without considering current form activity.
function levels.base(ctx, owner, mutation_id)
    local entry = records.find(ctx, owner, mutation_id)

    if not entry then
        return 0
    end

    local state = entry.state

    return state.innate + state.acquired + state.temporary
end

-- Example: an inactive base rank becomes zero before a Dragon Form rank is added.
-- Drop only fully inactive base ranks, then add rank supplied by the current form.
function levels.effective(ctx, owner, mutation_id)
    local forms = require("policy.magic.effects.forms.player")
    local base = levels.base(ctx, owner, mutation_id)

    if base > 0 and activity.level(ctx, owner, mutation_id, base) ==
        activity_levels.INACTIVE then
        base = 0
    end

    return base + forms.mutation_level(ctx, owner, mutation_id)
end

-- Exclude partial base activity as well as inactive activity before adding form rank.
function levels.full(ctx, owner, mutation_id)
    local forms = require("policy.magic.effects.forms.player")
    local base = levels.base(ctx, owner, mutation_id)

    if base > 0 and activity.level(ctx, owner, mutation_id, base) ~=
        activity_levels.FULL then
        base = 0
    end

    return base + forms.mutation_level(ctx, owner, mutation_id)
end

return levels
