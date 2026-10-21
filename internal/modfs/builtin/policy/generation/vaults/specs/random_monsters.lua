-- Example: A place:9 request raises effective depth before drawing from the monster pool.
local pool = require("policy.population.pool")
local choice = require("policy.generation.vaults.specs.choice")
local branches = require("ids.branches")
local tiers = require("data.demon_tiers")
local requests = require("constants.vault_monster_requests")
local monsters = require("ids.monsters")

local random_monsters = {}

-- DCSS's RANDOM_BASE_DRACONIAN draws an unspecialised colour. The removed
-- mottled draconian has no active combat profile and is deliberately absent.
local function base_draconian(ctx)
    -- Resolve the generated IDs at draw time, after catalog registration.
    local choices = {
        monsters.MONS_BLACK_DRACONIAN,
        monsters.MONS_GREEN_DRACONIAN,
        monsters.MONS_GREY_DRACONIAN,
        monsters.MONS_PALE_DRACONIAN,
        monsters.MONS_PURPLE_DRACONIAN,
        monsters.MONS_RED_DRACONIAN,
        monsters.MONS_WHITE_DRACONIAN,
        monsters.MONS_YELLOW_DRACONIAN,
    }

    return choices[ctx:random("vault_monster", #choices) + 1]
end

-- Source summon_any_demon chooses lesser, common, or greater with equal
-- chance, then applies the source sixty/forty split inside the latter two.
local function any_demon(ctx)
    local class = ctx:random("vault_monster", 3)
    local tier

    if class == 0 then
        tier = 5
    elseif class == 1 then
        tier = ctx:random("vault_monster", 10) < 6 and 4 or 3
    else
        tier = ctx:random("vault_monster", 10) < 6 and 2 or 1
    end

    local kinds = tiers[tier]

    return kinds[ctx:random("vault_monster", #kinds) + 1]
end

-- DCSS chooses class IV on six of ten outcomes, class III otherwise,
-- then chooses uniformly among that class's six source demon species.
-- Resolve IDs only when the draw occurs because catalog validation loads
-- this module before the generated ID registry is finalized.
local function common_demon(ctx)
    local tier

    if ctx:random("vault_monster", 10) < 6 then
        tier = tiers[4]
    else
        tier = tiers[3]
    end

    return tier[ctx:random("vault_monster", #tier) + 1]
end

-- DES place: requests 8 and 9 bias the monster pool above the floor depth by different curves.
local function effective_depth(request, depth)
    if request == "8" or request == "super_out_of_depth_monster" then
        return depth < 8 and depth * 2 or depth * 2 + math.min(depth - 8, 4)
    end

    if request == "9" or request == "moderate_out_of_depth_monster" then
        return depth < 5 and depth * 2 or depth + 5
    end

    return depth
end

-- Use the adjusted source depth to build a live pool before one weighted draw.
function random_monsters.pick(ctx, request, depth, site)
    if request == requests.BASE_DRACONIAN then
        return base_draconian(ctx)
    end
    if request == requests.ANY_DEMON then
        return any_demon(ctx)
    end

    if request == requests.COMMON_DEMON or
        request == requests.ANY_COMMON_DEMON then
        return common_demon(ctx)
    end

    local selected_depth = effective_depth(request, depth)
    local rows, total = pool.at_depth(branches.BRANCH_DUNGEON,
        selected_depth)

    if total <= 0 then
        choice.fail(site, request, "no eligible monster at depth " .. selected_depth)
    end

    return pool.pick(ctx, rows, total)
end

return random_monsters
