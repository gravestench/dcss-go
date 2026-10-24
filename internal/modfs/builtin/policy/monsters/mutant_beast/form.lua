-- Theory of operation: DCSS monster specs can name one mutant beast tier
-- and several hyphen-separated facets before "mutant beast". The catalog
-- ID stays MONS_MUTANT_BEAST; the authored form is separate per-actor
-- data for its hit dice, attacks, movement, and eventual corpse identity.
local choice = require("policy.generation.vaults.specs.choice")
local facet_ids = require("policy.monsters.mutant_beast.facets")

local form = {}

local tiers = {
    larval = 3,
    juvenile = 9,
    mature = 15,
    elder = 21,
    primal = 27,
}

local facets = {
    [facet_ids.STING] = true,
    [facet_ids.BAT] = true,
    [facet_ids.FIRE] = true,
    [facet_ids.WEIRD] = true,
    [facet_ids.SHOCK] = true,
    [facet_ids.OX] = true,
}

-- Decode the source spelling once during spec parsing. A typo must fail
-- at its DES line rather than becoming a new monster catalog lookup.
function form.parse(name, site, expression)
    local prefix = name:match("^(.-) mutant beast$")

    if not prefix then
        return nil
    end

    local tier, facet_text = prefix:match("^(%S+)%s+(%S+)$")

    if not tier or not tiers[tier] then
        choice.fail(site, expression, "invalid mutant beast tier")
    end

    local chosen = {}

    for facet in facet_text:gmatch("[^-]+") do
        if not facets[facet] then
            choice.fail(site, expression,
                "invalid mutant beast facet " .. facet)
        end

        chosen[#chosen + 1] = facet
    end

    if #chosen == 0 then
        choice.fail(site, expression, "missing mutant beast facet")
    end

    return {
        tier = tier,
        hit_dice = tiers[tier],
        facets = chosen,
    }
end

return form
