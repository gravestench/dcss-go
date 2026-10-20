-- The glass controller draws three common and six rare source pieces.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local ids = require("ids.vaults")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")

local test = {}

-- Products of separate source rolls favor fewer common and rare maps. Dis
-- omits the rare request, even though its column maps remain eligible.
local function controller_contract()
    local vault = catalog.get(ids.serial_glass)

    for _, branch_id in ipairs({
        branches.BRANCH_DUNGEON,
        branches.BRANCH_DIS,
    }) do
        local requests = {}
        local api = {
            context = {
                branch_id = branch_id,
            },
        }

        function api:roll(bound)
            return bound - 1
        end

        function api:place_maps(tag, count)
            requests[#requests + 1] = {
                tag = tag,
                count = count,
            }
        end

        hooks.run(vault, "place_glass", api)

        harness.equal(requests[1].tag, tags.SERIAL_GLASS,
            "source common glass tag")
        harness.equal(requests[1].count, 14,
            "source common glass maximum")
        harness.equal(#requests,
            branch_id == branches.BRANCH_DIS and 1 or 2,
            "Dis suppresses rare glass request")

        if branch_id ~= branches.BRANCH_DIS then
            harness.equal(requests[2].tag, tags.SERIAL_GLASS_RARE,
                "source rare glass tag")
            harness.equal(requests[2].count, 4,
                "source rare glass maximum")
        end
    end
end

-- The source variable-file pools now have real MAP definitions. All must
-- parse and place without depending on the missing rest of mini_features.
local function every_piece_places()
    local counts = {
        [tags.SERIAL_GLASS] = 0,
        [tags.SERIAL_GLASS_RARE] = 0,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        for tag in pairs(counts) do
            if definition.tags[tag] then
                counts[tag] = counts[tag] + 1

                local vault = catalog.get(id)
                local builder = grid.new({})

                function builder:roll()
                    return 0
                end

                local placed = placement.place(nil, builder, vault, {
                    branch_id = branches.BRANCH_DUNGEON,
                    depth = 12,
                    absolute_depth = 12,
                    branch_bottom = 15,
                    layout_family = "open",
                })

                harness.truthy(placed, "glass map places " .. id)
                harness.truthy(#vault.rows > 0, "glass MAP rows " .. id)

                if id == ids.unseen_surprise_small then
                    local found_awake = false

                    for _, record in ipairs(placed.records) do
                        if record.kind == effects.MONSTER then
                            found_awake = found_awake or
                                record.arguments.generate_awake
                        end
                    end

                    harness.truthy(found_awake,
                        "source awake monster intent survives placement")
                end
            end
        end
    end

    harness.equal(counts[tags.SERIAL_GLASS], 3,
        "all common glass columns")
    harness.equal(counts[tags.SERIAL_GLASS_RARE], 6,
        "all rare glass displays and surprises")
end

-- The authored unseen surprise becomes either inaccessible loot or an
-- awake unseen horror with one of two loot arrangements at deeper depths.
local function surprise_contract()
    local vault = catalog.get(ids.due_unseen_surprise)
    local emitted = {}
    local api = {}

    function api:absolute_depth()
        return 20
    end

    function api:roll()
        return 0
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    hooks.run(vault, "configure", api)

    local monsters = 0

    for _, operation in ipairs(emitted) do
        if operation.kind == directives.KMONS then
            monsters = monsters + 1
        end
    end

    harness.equal(monsters, 2,
        "deep surprise retains both unseen-horror instructions")

    emitted = {}

    -- D:10 short-circuits before any random draw and displays only loot.
    function api:absolute_depth()
        return 10
    end

    function api:roll()
        error("shallow display must not consume a danger draw")
    end

    hooks.run(vault, "configure", api)

    harness.equal(#emitted, 2, "shallow display has two substitutions")
    harness.equal(emitted[1].kind, directives.SUBST,
        "shallow display keeps its loot substitution")
end

-- The same source column map changes glass to crystal only in Dis.
local function dis_columns_contract()
    local vault = catalog.get(ids.glass_columns_a)
    local substitutions = {}
    local branch_id = branches.BRANCH_DUNGEON
    local api = {}

    function api:branch_id()
        return branch_id
    end

    function api:emit(kind, argument)
        substitutions[#substitutions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    hooks.run(vault, "glass_setup.dis_columns", api)
    harness.equal(#substitutions, 0, "Dungeon keeps glass pillars")

    branch_id = branches.BRANCH_DIS
    hooks.run(vault, "glass_setup.dis_columns", api)
    harness.equal(#substitutions, 1, "Dis changes glass pillars")
    harness.equal(substitutions[1].kind, directives.SUBST,
        "Dis change is a typed substitution")
    harness.equal(substitutions[1].argument, "m = b",
        "Dis source crystal glyph")
end

-- Verify real tagged maps, source count choices, and rare script behavior.
function test.run()
    controller_contract()
    every_piece_places()
    surprise_contract()
    dis_columns_contract()
end

return test
