-- Theory of operation: a rare serial controller rolls several independent
-- products. The common pool is available in Dis, where its source columns
-- turn glass to crystal; the rare display pool is skipped there entirely.
local branches = require("ids.branches")
local tags = require("constants.vault_tags")
local handler = {}

-- Keep each source multiplication explicit so the count distribution and
-- random draw order remain visible to a modder reading this one function.
local function place_glass(api)
    local common = 2 + api:roll(3) * api:roll(3) * api:roll(4)
    local rare = api:roll(2) * api:roll(2) * api:roll(5)

    api:place_maps(tags.SERIAL_GLASS, common)

    if api.context.branch_id ~= branches.BRANCH_DIS then
        api:place_maps(tags.SERIAL_GLASS_RARE, rare)
    end
end

handler.place_glass = place_glass

return handler
