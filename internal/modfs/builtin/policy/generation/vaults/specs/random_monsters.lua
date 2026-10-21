-- Example: A place:9 request raises effective depth before drawing from the monster pool.
local pool = require("policy.population.pool")
local choice = require("policy.generation.vaults.specs.choice")
local branches = require("ids.branches")
local categories = require("constants.catalog")
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

-- RANDOM_NONBASE_DRACONIAN chooses uniformly among the six active source
-- draconian jobs. Colour/job combinations are then owned by the normal
-- monster profile rather than invented here in the DES name parser.
local function nonbase_draconian(ctx)
    local choices = {
        monsters.MONS_DRACONIAN_STORMCALLER,
        monsters.MONS_DRACONIAN_MONK,
        monsters.MONS_DRACONIAN_SHIFTER,
        monsters.MONS_DRACONIAN_ANNIHILATOR,
        monsters.MONS_DRACONIAN_KNIGHT,
        monsters.MONS_DRACONIAN_SCORCHER,
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
local function effective_depth(request, depth, branch_id)
    local branch = register.get(categories.BRANCHES, branch_id)

    -- DCSS leaves OOD requests unchanged in one-floor portal branches.
    if branch.depth <= 1 then
        return depth
    end

    if request == "8" or request == "super_out_of_depth_monster" then
        local bonus = 4

        if branch_id == branches.BRANCH_DUNGEON then
            bonus = math.max(0, math.min(depth - 8, 4))
        end

        return depth * 2 + bonus
    end

    if request == "9" or request == "moderate_out_of_depth_monster" then
        local selected = depth + 5

        if branch_id == branches.BRANCH_DUNGEON then
            selected = math.min(selected, depth * 2)
        end

        return selected
    end

    return depth
end

-- Use the adjusted source depth to build a live pool before one weighted draw.
function random_monsters.pick(ctx, request, depth, site, place)
    if request == requests.BASE_DRACONIAN then
        return base_draconian(ctx)
    end

    if request == requests.NONBASE_DRACONIAN then
        return nonbase_draconian(ctx)
    end
    if request == requests.ANY_DEMON then
        return any_demon(ctx)
    end

    if request == requests.COMMON_DEMON or
        request == requests.ANY_COMMON_DEMON then
        return common_demon(ctx)
    end

    -- A map's place:D:N override changes both the population branch and
    -- its local depth; otherwise random requests use the current branch.
    local explicit_depth = place and place:match("^D:(%d+)$")
    local branch_id = explicit_depth and branches.BRANCH_DUNGEON or
        site and site.branch_id or branches.BRANCH_DUNGEON
    local local_depth = tonumber(explicit_depth) or
        site and site.local_depth or depth
    local selected_depth = effective_depth(request, local_depth, branch_id)
    local branch = register.get(categories.BRANCHES, branch_id)

    -- Source mon-place caps every out-of-depth request. Most branches use
    -- their floor count; only branches with a larger source cap declare
    -- ood_cap in their catalog file.
    selected_depth = math.min(selected_depth,
        branch.ood_cap or branch.depth)

    local rows, total = pool.at_depth(branch_id,
        selected_depth)

    -- Temple has no ordinary spawn rows, but the rare corrupted Temple
    -- authors a random monster in its map. Draw that explicit request from
    -- the parent Dungeon at the Temple's absolute depth. This does not add
    -- ambient Temple population or change branches with their own rows.
    if total <= 0 and branch_id == branches.BRANCH_TEMPLE and
        not explicit_depth then
        local branch = register.get(categories.BRANCHES, branch_id)
        local dungeon_depth = site and site.absolute_depth or
            branch.absolute_depth

        selected_depth = effective_depth(request, dungeon_depth,
            branches.BRANCH_DUNGEON)
        rows, total = pool.at_depth(branches.BRANCH_DUNGEON,
            selected_depth)
    end

    if total <= 0 then
        choice.fail(site, request, "no eligible monster at depth " .. selected_depth)
    end

    return pool.pick(ctx, rows, total)
end

return random_monsters
