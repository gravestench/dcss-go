-- A sparse Pan layer adds a primary and replaces one source hook by its
-- exact path. Both are discovered through the production effective catalog.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local selector = require("policy.generation.pan.selection")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Find a hook's emitted directive without reproducing parser logic.
local function emits(operations, kind, argument)
    for _, operation in ipairs(operations) do
        if operation.kind == kind and operation.argument == argument then
            return true
        end
    end

    return false
end

-- Check the effective weighted pool and execute both named hook paths.
function test.run()
    local weight

    for _, candidate in ipairs(selector.candidates({})) do
        if candidate.definition.id == "modded_pan_alcove" then
            weight = candidate.weight
        end
    end

    harness.equal(weight, 7, "new Pan primary joins weighted selection")

    local added = hooks.expand(vaults.get("modded_pan_alcove"), {})

    harness.truthy(emits(added, directives.SUBST, "a = ."),
        "new Pan map resolves its own Lua hook")

    local source = {
        roll = function(_, bound)
            harness.equal(bound, 15, "source hook keeps its draw")
            return 0
        end,
    }
    local replaced = hooks.expand(
        vaults.get("nicolae_pan_strange_glyphs"), source)

    harness.truthy(emits(replaced, directives.SUBST, "a = a"),
        "same-path Pan hook override wins")
end

return test
