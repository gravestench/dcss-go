-- Natural monster bands have source placement gates separate from their
-- follower roster. Each named rule receives the leader's content profile;
-- returning nil means this arrival has no band on the current floor.
local branches = require("ids.branches")
local branch_flags = require("constants.branch_flags")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local conditions = {}
local rules = {}

-- Content validation checks named predicates before a game samples one.
function conditions.known(name)
    return type(rules[name]) == "function"
end

-- The level record carries branch-local depth during population. Wrath
-- can ask the active grid for the same value after the floor is generated.
local function local_depth(ctx, level)
    return level.local_depth or ctx:level_depth(level.id) or 1
end

-- Source env.absdepth0 combines the branch's catalog origin with local
-- depth. Source `you.depth` gates below use local depth separately.
local function absolute_depth(ctx, level)
    local branch_id = ctx:level_branch(level.id)
    local branch = catalog.get(categories.BRANCHES, branch_id)

    return branch.absolute_depth + local_depth(ctx, level) - 1
end

-- Member policies use the same source depth without copying branch math.
conditions.absolute_depth = absolute_depth

-- Orc warlords bring a large mixed army outside Vaults. Within Vaults the
-- source replaces that with a small escort of orc knights.
function rules.orc_warlord(ctx, level, profile)
    if ctx:level_branch(level.id) ~= branches.BRANCH_VAULTS then
        return profile
    end

    return {
        min = 2,
        max = 4,
        slots = {
            { monsters.MONS_ORC_KNIGHT },
        },
    }
end

-- The ordinary centaur-warrior pack is rare and deep. Vaults instead gives
-- the leader a small group of its own kind regardless of that first gate.
function rules.centaur_warrior(ctx, level, profile)
    local branch = ctx:level_branch(level.id)
    local passed = ctx:random(streams.BANDS, 3) == 0 and
        absolute_depth(ctx, level) >= 10 and
        branch ~= branches.BRANCH_SHOALS and
        branch ~= branches.BRANCH_VAULTS

    if passed then
        return profile
    end

    if branch == branches.BRANCH_VAULTS then
        return {
            min = 2,
            max = 4,
            slots = {
                { monsters.MONS_CENTAUR_WARRIOR },
            },
        }
    end

    return nil
end

-- Naga warriors bring escorts reliably outside Snake. Snake's early floors
-- suppress the pack with the source depth-in-five probability.
function rules.naga(ctx, level, profile)
    if ctx:level_branch(level.id) ~= branches.BRANCH_SNAKE then
        return profile
    end

    local chance = local_depth(ctx, level)

    if chance >= 5 or ctx:random(streams.BANDS, 5) < chance then
        return profile
    end

    return nil
end

-- Merfolk officers travel alone in Depths. On Shoals floors their chance
-- to bring troops rises with depth, reaching certainty at the fifth floor.
function rules.merfolk(ctx, level, profile)
    local branch = ctx:level_branch(level.id)

    if branch == branches.BRANCH_DEPTHS then
        return nil
    end

    if branch == branches.BRANCH_SHOALS then
        local chance = local_depth(ctx, level)

        if chance < 5 and ctx:random(streams.BANDS, 5) >= chance then
            return nil
        end
    end

    return profile
end

-- Basic draconians bring a pack only in branches where source level travel
-- is connected. The chance and absolute-depth gate live on their profile.
function rules.base_draconian(ctx, level, profile)
    local branch = catalog.get(categories.BRANCHES,
        ctx:level_branch(level.id))

    for _, flag in ipairs(branch.flags or {}) do
        if flag == branch_flags.NO_X_LEVEL_TRAVEL then
            return nil
        end
    end

    return profile
end

-- Simple source chance and depth fields are data on the monster. More
-- involved branch gates use the small named functions above.
function conditions.select(ctx, level, profile)
    if profile.chance_denominator and
        ctx:random(streams.BANDS, profile.chance_denominator) ~= 0 then
        return nil
    end

    if profile.min_depth and
        absolute_depth(ctx, level) < profile.min_depth then
        return nil
    end

    if profile.condition then
        local rule = rules[profile.condition]

        if not rule then
            error("unknown monster band condition " .. profile.condition)
        end

        return rule(ctx, level, profile)
    end

    return profile
end

return conditions
