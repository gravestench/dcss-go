local pool = require("policy.population.pool")
local choice = require("policy.generation.vaults.specs.choice")

local random_monsters = {}

local function effective_depth(request, depth)
    if request == "8" or request == "super_out_of_depth_monster" then
        return depth < 8 and depth * 2 or depth * 2 + math.min(depth - 8, 4)
    end

    if request == "9" or request == "moderate_out_of_depth_monster" then
        return depth < 5 and depth * 2 or depth + 5
    end

    return depth
end

function random_monsters.pick(ctx, request, depth, site)
    local selected_depth = effective_depth(request, depth)
    local rows, total = pool.at_depth(selected_depth)

    if total <= 0 then
        choice.fail(site, request, "no eligible monster at depth " .. selected_depth)
    end

    return pool.pick(ctx, rows, total)
end

return random_monsters
