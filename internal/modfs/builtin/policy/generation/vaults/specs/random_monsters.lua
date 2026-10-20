-- Example: A place:9 request raises effective depth before drawing from the monster pool.
local pool = require("policy.population.pool")
local choice = require("policy.generation.vaults.specs.choice")
local monster_ids = require("ids.monsters")

local random_monsters = {}

-- DCSS chooses class IV on six of ten outcomes, class III otherwise,
-- then chooses uniformly among that class's six source demon species.
-- Resolve IDs only when the draw occurs because catalog validation loads
-- this module before the generated ID registry is finalized.
local function common_demon(ctx)
    local tier

    if ctx:random("vault_monster", 10) < 6 then
        tier = {
            monster_ids.MONS_ICE_DEVIL,
            monster_ids.MONS_RUST_DEVIL,
            monster_ids.MONS_ORANGE_DEMON,
            monster_ids.MONS_RED_DEVIL,
            monster_ids.MONS_CHAOS_SPAWN,
            monster_ids.MONS_HELLWING,
        }
    else
        tier = {
            monster_ids.MONS_SUN_DEMON,
            monster_ids.MONS_SOUL_EATER,
            monster_ids.MONS_SMOKE_DEMON,
            monster_ids.MONS_NEQOXEC,
            monster_ids.MONS_YNOXINUL,
            monster_ids.MONS_SIXFIRHY,
        }
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
    if request == "common demon" or request == "any common demon" then
        return common_demon(ctx)
    end

    local selected_depth = effective_depth(request, depth)
    local rows, total = pool.at_depth(selected_depth)

    if total <= 0 then
        choice.fail(site, request, "no eligible monster at depth " .. selected_depth)
    end

    return pool.pick(ctx, rows, total)
end

return random_monsters
