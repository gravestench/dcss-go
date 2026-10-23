-- The entrance helper must emit the source timer once at its DES site.
-- A fixed draw catches accidental rerolls when population later creates
-- the live Akara gate from this marker.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local wizlab = require("constants.wizlab")
local shared = require("policy.generation.vaults.wizlab_entry.shared")
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local rooms = require("policy.generation.wizlab.level")
local doroklohe = require(
    "policy.generation.vaults.wizlab.wizlab_doroklohe")

local test = {}

-- Capture the production hook's emitted directives without reimplementing
-- the parser or duplicating the game's marker schema in this test.
local function capture()
    local api = {
        operations = {},
        rolls = 0,
    }

    function api:roll(bound)
        self.rolls = self.rolls + 1
        harness.equal(bound, wizlab.DURATION_RANGE_TURNS,
            "Wizard Lab source duration range")

        return 0
    end

    function api:emit(kind, argument)
        self.operations[#self.operations + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    return api
end

-- Drive every source hook through real DES placement, where declarations,
-- transformations, and typed records interact. A seeded context keeps
-- the test independent of host file enumeration order.
local function place_rooms()
    for _, path in ipairs(mod.paths("vaults/wizlab", ".des")) do
        local id = path:match("([^/]+)%.des$")
        local next_value = 17
        local context = {}

        function context:random_u64()
            next_value = (next_value * 48271) % 2147483647

            return 0, next_value
        end

        -- Population policies draw from named streams through ctx:random;
        -- the fixture supplies the same deterministic source of bits.
        function context:random(_stream, bound)
            self:random_u64()

            return next_value % bound
        end

        local builder = grid.new(context)
        local player = {
            branch_id = branches.BRANCH_DEPTHS,
            depth = 1,
            branch_bottom = 1,
            absolute_depth = 20,
            map_tag = "wizlab",
        }
        local okay, result = pcall(placement.place,
            context, builder, catalog.get(id), player, {
                whole_level = true,
            })

        harness.truthy(okay, id .. " source hooks: " .. tostring(result))
        harness.truthy(result and #result.occupied > 0,
            id .. " placed no cells")

        local generated_okay, generated = pcall(rooms.generate,
            context, {
                layout_id = id,
            })

        harness.truthy(generated_okay,
            id .. " staged floor: " .. tostring(generated))
        harness.equal(generated.level.vault_id, id,
            id .. " selected its requested source room")
    end
end

-- The source's round and grid branches are exclusive. A local capture
-- checks their emitted directives without redeclaring DES syntax.
local function doroklohe_layout_choice(choice)
    local api = {
        values = {},
        emitted = {},
    }

    function api:roll(bound)
        harness.equal(bound, 13, "source Doroklohe layout range")

        return choice
    end

    function api:remember(name, value)
        self.values[name] = value
    end

    function api:recall(name)
        return self.values[name]
    end

    function api:emit(kind, argument)
        self.emitted[#self.emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    doroklohe.site_2(api)
    doroklohe.site_3(api)
    doroklohe.site_4(api)

    local round = false
    local grid = false

    for _, emitted in ipairs(api.emitted) do
        round = round or emitted.kind == directives.COLOUR and
            emitted.argument == "_ = darkgrey"
        grid = grid or emitted.kind == directives.SHUFFLE and
            emitted.argument == "bcdefghijklm"
    end

    return round, grid
end

-- The source timer is represented as one fixed value in a typed marker;
-- the feature assignment remains a separate DES operation.
function test.run()
    local api = capture()

    shared.portal(api)

    harness.equal(api.rolls, 1, "one source lifetime draw")
    harness.equal(api.operations[1].kind, directives.MARKER,
        "timer marker before portal feature")
    harness.truthy(api.operations[1].argument:find("low = 600", 1, true),
        "minimum source timer")
    harness.equal(api.operations[2].kind, directives.KFEAT,
        "portal feature after timer")
    harness.equal(api.operations[2].argument,
        "O = " .. wizlab.ENTRY_FEATURE,
        "the source O glyph becomes the Wizard Lab entrance")

    place_rooms()

    local round, grid = doroklohe_layout_choice(0)
    harness.truthy(not round and grid,
        "rare regular grid excludes round directives")

    round, grid = doroklohe_layout_choice(11)
    harness.truthy(round and not grid,
        "round room excludes grid directives")
end

return test
