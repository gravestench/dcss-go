-- Committed arrival maps supply the marker expression under test. The
-- parser may not replace their source parameters with a hand-written copy.
local catalog = require("policy.generation.vaults.catalog")
local effects = require("constants.vault_effects")
local fog = require("policy.world.fog_machine_definitions")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local clouds = require("ids.clouds")
local vaults = require("ids.vaults")
local des = require("policy.generation.vaults.des")
local directives = require("constants.vault_directives")
local branches = require("ids.branches")
local ice = require("policy.generation.vaults.serial.ice_setup")
local storm = require("policy.generation.vaults.temple.hellmonk_temple_of_storms")

local test = {}

-- Read the first live fog marker from a placed source map, including its
-- joined DES continuation and transformed cell coordinates.
local function source_marker(ctx, vault_id)
    local map = catalog.get(vault_id)
    local placed = placement.place(ctx, grid.new(ctx), map)

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MARKER and
            record.identity:find("lua:fog_machine", 1, true) then
            return record
        end
    end

    error("source vault has no fog machine " .. vault_id)
end

-- Source defaults and explicit miasma fields resolve to registered cloud
-- definitions without retyping either DES marker in this test.
local function committed_definitions(ctx)
    local mist = source_marker(ctx, vaults.dpeg_arrival_fog)
    local mist_state = fog.parse(mist.identity, mist)

    harness.equal(mist_state.kind_id, clouds.CLOUD_MIST,
        "default fog kind")
    harness.equal(mist_state.pow_max, 5, "authored maximum power")
    harness.equal(mist_state.delay_min, 10, "authored minimum delay")
    harness.equal(mist_state.delay_max, 150, "authored maximum delay")
    harness.equal(mist_state.size_min, 5, "authored cloud area size")
    harness.equal(mist_state.start_clouds, 1, "entry burst default")

    local miasma = source_marker(ctx, vaults.saegor_arrival_miasma)
    local miasma_state = fog.parse(miasma.identity, miasma)

    harness.equal(miasma_state.kind_id, clouds.CLOUD_MIASMA,
        "source cloud type")
    harness.equal(miasma_state.delay_min, 5,
        "single delay becomes lower bound")
    harness.equal(miasma_state.delay_max, 5,
        "single delay becomes upper bound")
    harness.equal(miasma_state.exclusion_radius, 0,
        "explicit cloud exclusion radius")
end

-- A mod mistake is reported when its marker is parsed instead of silently
-- becoming a default mist source with an unbounded timer.
local function invalid_definitions()
    harness.falsy(pcall(fog.parse,
        'lua:fog_machine { size = 1, delay = 10 }', {}),
        "missing maximum power passed")
    harness.falsy(pcall(fog.parse,
        'lua:fog_machine { pow_max = 4, size = 1 }', {}),
        "missing delay passed")
    harness.falsy(pcall(fog.parse,
        'lua:fog_machine { pow_max = 4, delay = 10, size = 1, ' ..
            'cloud_type = "unknown fog" }', {}),
        "unknown cloud kind passed")
end

-- Every committed DES marker must use a table shape the live reader can
-- load. This catches source content drift during an intentional refresh.
local function all_committed_markers()
    local count = 0

    for _, path in ipairs(mod.paths("vaults", ".des")) do
        local definition = des.parse(path, mod.read(path))

        for _, operation in ipairs(definition.operations) do
            if operation.kind == directives.MARKER and
                operation.argument:find("lua:fog_machine", 1, true) then
                local identity = operation.argument:match("^.-=%s*(.*)$")

                harness.truthy(identity, "fog marker has no constructor")
                fog.parse(identity, {
                    path = path,
                    line = operation.line,
                    vault_id = definition.id,
                })
                count = count + 1
            end
        end
    end

    harness.truthy(count >= 60, "fog catalog unexpectedly shrank")
end

-- Named generation hooks also produce fog markers at runtime. Capture the
-- values they actually emit so tests cannot drift from production strings.
local function hook_markers()
    local marker
    local api = {}

    -- The Dungeon branch selects the ice helper's mist variant.
    function api:branch_id()
        return branches.BRANCH_DUNGEON
    end

    -- Unrelated ice terrain directives need no generation side effects here.
    function api:emit(kind, argument)
        if kind == directives.MARKER then
            marker = argument:match("^.-=%s*(.*)$")
        end
    end

    -- Preserve the source marker emitted by the real ice helper.
    function api:record(kind, record)
        if kind == effects.MARKER then
            marker = record.identity
        end
    end

    -- Choose the storm marker instead of the rare obelisk alternative.
    function api:roll()
        return 1
    end

    ice.configure(api)
    harness.equal(fog.parse(marker, {}).kind_id, clouds.CLOUD_MIST,
        "ice hook cloud kind")

    storm.choose_storm(api)
    harness.equal(fog.parse(marker, {}).kind_id, clouds.CLOUD_STORM,
        "Temple storm hook cloud kind")
end

-- Execute the real reader against both source definitions and bad mod input.
function test.run(ctx)
    committed_definitions(ctx)
    invalid_definitions()
    all_committed_markers()
    hook_markers()
end

return test
