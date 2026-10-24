-- Sacrifice Drink is pointless when No Drink already prevents potions.
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local rule = {}

-- Source sacrifice-data.h checks this separately from the safety rank cap.
function rule.eligible(ctx, player)
    return levels.base(ctx, player, mutations.MUT_NO_DRINK) == 0
end

return rule
