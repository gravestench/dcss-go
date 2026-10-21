-- Theory of operation: source DCSS chooses one Hell branch for the Serpent
-- when an ending first needs that answer. Store the choice on the player's
-- unique history so every later ending, revisit, and save reads one answer.
-- The named DES hooks call setup at their original script position.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local choices = require("constants.unique_choices")
local directives = require("constants.vault_directives")
local history = require("policy.population.unique_history")
local catalog = require("policy.catalog")
local streams = require("constants.rng_streams")

local serpent = {}

local homes = {
    branches.BRANCH_GEHENNA,
    branches.BRANCH_COCYTUS,
    branches.BRANCH_DIS,
    branches.BRANCH_TARTARUS,
}

-- Draw once from the named stream, then use the saved player component.
-- This is called before building a seventh floor so its hook can only read.
function serpent.branch(ctx)
    return history.choice(ctx, choices.HELL_SERPENT_BRANCH, homes,
        streams.HELL_SERPENT)
end

-- A source map owns glyph D. Only the selected branch's seventh floor
-- turns that glyph into the Serpent, and a previous unique claim wins.
function serpent.setup(api, spec)
    if api:run_choice(choices.HELL_SERPENT_BRANCH) ~= spec.branch_id or
        api:branch_id() ~= spec.branch_id or
        api:depth() ~= api:branch_bottom() or
        api:unique_seen(spec.monster_id) then
        return
    end

    local definition = catalog.get(categories.MONSTERS, spec.monster_id)

    api:emit(directives.KMONS, spec.glyph .. " = " .. definition.name)
end

return serpent
