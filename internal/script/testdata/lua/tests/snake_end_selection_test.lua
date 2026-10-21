-- End vaults use the effective source catalog, but their mandatory draw
-- must be independent of ordinary optional PLACE maps and file order.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local end_vault = require("policy.generation.vaults.end")
local availability = require("policy.generation.floor_availability")
local used = require("policy.generation.vaults.used")

local test = {}

-- These are branch facts, not a duplicate vault declaration. Production
-- generation supplies the same facts from the registered branch object.
local function snake_context()
    return {
        branch_id = branches.BRANCH_SNAKE,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 18,
        end_vault_family = "snake_end",
    }
end

-- The weighted choice must spend one draw and include every positive
-- source ending exactly once, regardless of VFS discovery order.
function test.run()
    local candidates = end_vault.candidates(snake_context())
    local seen = {}
    local total_weight = 0

    harness.equal(#candidates, 9, "all nine required Snake endings")

    for index, candidate in ipairs(candidates) do
        local id = candidate.definition.id

        harness.equal(candidate.definition.family, "snake_end",
            "end family")
        harness.falsy(seen[id], "unique candidate " .. id)
        seen[id] = true
        total_weight = total_weight + candidate.weight

        if index > 1 then
            harness.truthy(candidates[index - 1].definition.id < id,
                "ID sorted candidate order")
        end
    end

    local random = { draws = 0 }

    -- Force the last cumulative bucket while counting actual draws.
    function random:roll(bound)
        self.draws = self.draws + 1
        harness.equal(bound, total_weight, "weighted bound")

        return bound - 1
    end

    local selected = end_vault.choose(random, candidates)

    harness.equal(selected.id, candidates[#candidates].definition.id,
        "last weighted bucket")
    harness.equal(random.draws, 1, "one selection draw")

    local other = snake_context()

    other.branch_id = branches.BRANCH_SPIDER
    harness.equal(#end_vault.candidates(other), 0,
        "Snake PLACE maps do not select for Spider")

    local placed = {}
    local context = snake_context()

    context.used = used.new({})

    local fit_calls = 0

    -- This seam checks the mandatory selector's commit contract. Separate
    -- placement tests exercise real geometry and connector behavior.
    local function fit(_, _, map)
        fit_calls = fit_calls + 1

        return {
            id = map.id,
            records = {},
            occupied = {},
        }
    end

    local okay = pcall(end_vault.place,
        nil, random, context, placed, fit)

    harness.falsy(okay, "end map without a rune is rejected")
    harness.equal(fit_calls, 1, "one end map fit")
    harness.equal(#placed, 0, "invalid end map is never published")
    harness.equal(#context.used:ids(), 0,
        "invalid end map never enters save history")

    -- A rejected base layout must not reroll the authored end map. Only
    -- geometry changes on retry; otherwise a cramped map biases weights.
    local retry_choice = {}
    local retry_context = snake_context()

    retry_context.used = used.new({})
    retry_context.end_choice = retry_choice

    local retry_random = { draws = 0 }

    function retry_random:roll(bound)
        self.draws = self.draws + 1
        return bound - 1
    end

    local rejected = pcall(end_vault.place, nil, retry_random,
        retry_context, {}, function()
            return nil, "stair conflict"
        end)

    harness.falsy(rejected, "first base layout rejects end map")
    harness.truthy(retry_choice.id, "selected end survives rejection")

    local branch = register.get(categories.BRANCHES,
        branches.BRANCH_SNAKE)
    local retry_placed = {}
    local retry_id = end_vault.place(nil, retry_random,
        retry_context, retry_placed, function(_, _, map)
            return {
                id = map.id,
                records = {
                    {
                        kind = require("constants.vault_effects").ITEM,
                        arguments = {
                            kind_id = branch.runes[1],
                        },
                    },
                },
            }
        end)

    harness.equal(retry_id, retry_choice.id,
        "retry keeps original end vault")
    harness.equal(retry_random.draws, 1,
        "retry does not spend a second weighted draw")

    harness.equal(branch.end_vault_family, "snake_end",
        "Snake declares its end family")
    harness.truthy(branch.end_vault_required,
        "Snake requires its end encounter")
    harness.truthy(availability.can_build(branches.BRANCH_SNAKE, 4),
        "source end pool opens Snake:4")

    local original_get = register.get

    -- The Go catalog returns copies. Intercept one read to simulate a mod
    -- that declares a family with no effective end maps.
    register.get = function(category, id)
        local definition = original_get(category, id)

        if category == categories.BRANCHES and
            id == branches.BRANCH_SNAKE then
            definition.end_vault_family = "missing_end_family"
        end

        return definition
    end

    local okay, missing = pcall(availability.can_build,
        branches.BRANCH_SNAKE, 4)

    register.get = original_get

    harness.truthy(okay, "missing family remains queryable")
    harness.falsy(missing, "missing end pool seals Snake:4")
end

return test
