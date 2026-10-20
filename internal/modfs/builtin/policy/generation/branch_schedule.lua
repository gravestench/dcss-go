-- One run chooses its ordinary branch entrances once. The selected depths
-- are saved because later Dungeon floors use them without redrawing RNG.
-- Source ranges come from content/branches; portals and rootless branches
-- remain under their own travel rules.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local streams = require("constants.rng_streams")

local schedule = {}

local water = {
    branches.BRANCH_SWAMP,
    branches.BRANCH_SHOALS,
}

local poison = {
    branches.BRANCH_SNAKE,
    branches.BRANCH_SPIDER,
}

-- A finite range alone is insufficient: Ziggurat is a portal and Hell's
-- children have no ordinary path because the Vestibule is rootless.
local function ordinary(branch, by_id, visiting)
    if branch.id == branches.BRANCH_DUNGEON then
        return true
    end

    if branch.depth < 1 or branch.min_depth < 1 or
        branch.max_depth < branch.min_depth then
        return false
    end

    for _, flag in ipairs(branch.flags or {}) do
        if flag == "no_x_level_travel" then
            return false
        end
    end

    local parent = by_id[branch.parent_id]

    if not parent or branch.max_depth > parent.depth or
        visiting[branch.id] then
        return false
    end

    visiting[branch.id] = true
    local reachable = ordinary(parent, by_id, visiting)
    visiting[branch.id] = nil

    return reachable
end

-- Read one effective catalog in stable ID order. The same filtered set is
-- used to draw and later validate saved entries, so a mod cannot silently
-- move a branch by changing file discovery order.
local function ordinary_definitions()
    local all = catalog.all(categories.BRANCHES)
    local by_id = {}
    local result = {}

    for _, branch in ipairs(all) do
        by_id[branch.id] = branch
    end

    for _, branch in ipairs(all) do
        if branch.id ~= branches.BRANCH_DUNGEON and
            ordinary(branch, by_id, {}) then
            result[#result + 1] = branch
        end
    end

    table.sort(result, function(left, right)
        return left.id < right.id
    end)

    return result
end

-- The source disables one of each Lair pair. Saving the enabled ID makes
-- the later entrance graph explicit and immune to a second choice draw.
function schedule.choose(ctx)
    local water_id = water[ctx:random(streams.BRANCH_SCHEDULE, #water) + 1]
    local poison_id = poison[ctx:random(streams.BRANCH_SCHEDULE, #poison) + 1]
    local chosen = {
        water_branch_id = water_id,
        poison_branch_id = poison_id,
        entries = {},
    }

    for _, branch in ipairs(ordinary_definitions()) do
        local disabled_water = (branch.id == water[1] or
            branch.id == water[2]) and branch.id ~= water_id
        local disabled_poison = (branch.id == poison[1] or
            branch.id == poison[2]) and branch.id ~= poison_id

        if not disabled_water and not disabled_poison then
            local range = branch.max_depth - branch.min_depth + 1

            chosen.entries[branch.id] = {
                parent_id = branch.parent_id,
                parent_depth = branch.min_depth +
                    ctx:random(streams.BRANCH_SCHEDULE, range),
            }
        end
    end

    return chosen
end

-- Validate a restored schedule against the effective catalog and both
-- source swap pairs before any pending entrance can be traversed.
function schedule.validate(chosen)
    if type(chosen) ~= "table" or type(chosen.entries) ~= "table" then
        error("branch schedule is missing entries")
    end

    local water_ok = chosen.water_branch_id == water[1] or
        chosen.water_branch_id == water[2]
    local poison_ok = chosen.poison_branch_id == poison[1] or
        chosen.poison_branch_id == poison[2]

    if not water_ok or not poison_ok then
        error("branch schedule has invalid Lair branch pair")
    end

    local expected = {}

    for _, branch in ipairs(ordinary_definitions()) do
        local disabled = (branch.id == water[1] or branch.id == water[2]) and
            branch.id ~= chosen.water_branch_id or
            (branch.id == poison[1] or branch.id == poison[2]) and
            branch.id ~= chosen.poison_branch_id

        if not disabled then
            expected[branch.id] = true

            local entry = chosen.entries[branch.id]

            if type(entry) ~= "table" or
                entry.parent_id ~= branch.parent_id or
                type(entry.parent_depth) ~= "number" or
                entry.parent_depth % 1 ~= 0 or
                entry.parent_depth < branch.min_depth or
                entry.parent_depth > branch.max_depth then
                error("branch schedule has invalid " .. branch.id .. " entrance")
            end
        end
    end

    for branch_id in pairs(chosen.entries) do
        if not expected[branch_id] then
            error("branch schedule has unscheduled " .. tostring(branch_id))
        end
    end

    return true
end

-- Return only entrances assigned to this floor, sorted by stable branch ID.
-- The source feature remains attached to the entry for the renderer and
-- eventual specific branch travel policy.
function schedule.entries(chosen, parent_id, local_depth)
    local found = {}

    for _, branch in ipairs(ordinary_definitions()) do
        local entry = chosen.entries[branch.id]

        if entry and entry.parent_id == parent_id and
            entry.parent_depth == local_depth then
            found[#found + 1] = {
                branch_id = branch.id,
                parent_id = parent_id,
                parent_depth = local_depth,
                entry_feature = branch.entry_feature,
            }
        end
    end

    return found
end

-- The Go save owner invokes this after restoring the Lua runtime. Lua checks
-- source branch facts rather than duplicating range tables in snapshot code.
function schedule.validate_saved(_, input)
    schedule.validate(input.branch_schedule)

    return {}
end

register.policy({
    id = "world.validate_branch_schedule",
    run = schedule.validate_saved,
})

return schedule
