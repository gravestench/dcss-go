-- Ru offers Arcana only once, even if a later mutation change could make
-- another school in every severity group eligible again.
local levels = require("policy.mutations.levels")
local pools = require("constants.ru_variant_pools")
local source_pools = require("data.ru_variant_mutations")

local rule = {}

-- One previously sacrificed school anywhere in the pool disqualifies the
-- whole Arcana offer, matching the source's special validity check.
function rule.eligible(ctx, player)
    for _, severity in ipairs(source_pools[pools.ARCANA]) do
        for _, id in ipairs(severity) do
            if levels.base(ctx, player, id) > 0 then
                return false
            end
        end
    end

    return true
end

return rule
