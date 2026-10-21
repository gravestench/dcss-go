-- Every ordinary source Dis map must remain an independently selectable
-- definition and survive the real DES placement pipeline.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Use a reproducible draw stream while preserving the production builder.
local function random_context()
    local state = 41
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state
        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- The first Dis level admits the shared depth rule; deeper levels also
-- admit the explicitly Dis:2- maps from the source ordinary section.
function test.run()
    vaults.load()

    local count = 0
    local context = {
        branch_id = branches.BRANCH_DIS,
        depth = 2,
        branch_bottom = 7,
        absolute_depth = 25,
        branch_vault_family = "dis",
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "dis" then
            count = count + 1
            harness.truthy(#definition.depths > 0,
                id .. " lost its source Dis depth")

            local player = {
                branch_id = branches.BRANCH_DIS,
                depth = 2,
                branch_bottom = 7,
                absolute_depth = 25,
            }
            local placed = placement.place(nil,
                grid.new(random_context()), definition, player)

            harness.equal(placed.id, id,
                "Dis source map keeps its authored identity")

            if id == "grunt_dis_stairs_iron_hall" then
                local movement = 0
                local statues = 0

                for _, record in ipairs(placed.records) do
                    if record.kind == effects.MARKER and
                        record.identity ==
                            "vault_trigger:dis.iron_hall_animate" then
                        movement = movement + 1
                    elseif record.kind == effects.MARKER and
                        record.identity ==
                            "vault_trigger:dis.trap_statue" then
                        statues = statues + 1
                    end
                end

                harness.truthy(movement > 0,
                    "iron hall lost its movement triggers")
                harness.truthy(statues > 0,
                    "iron hall lost its animated statue targets")
            end
        end
    end

    harness.equal(count, 36, "ordinary Dis source map count")

    local selectable = regular.candidates(context)

    harness.truthy(#selectable > 0,
        "ordinary Dis maps must enter the regular pool")

    for _, candidate in ipairs(selectable) do
        harness.equal(candidate.definition.family, "dis",
            "a different branch entered the Dis pool")
    end
end

return test
