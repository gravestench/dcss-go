-- Source Zot content is one discoverable family. A mod may replace an
-- individual DES file without changing a Go or Lua registration list.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local families = require("constants.vault_families")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local items = require("ids.items")
local layouts = require("policy.generation.layouts.catalog")
local entry = require("policy.generation.vaults.branch_entry")
local vaults = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local regular = require("policy.generation.vaults.regular")
local trigger_ids = require("constants.vault_triggers")

local test = {}

-- Give each map its own reproducible layout stream. A catalog check cannot
-- show whether a source MAP can actually pass the shared placement engine.
local function random_context(seed)
    local state = seed
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- The dummy is deliberately selectable as a weighted no-op. Every other
-- ordinary Zot definition must fit directly before it can enter the pool.
local function place_ordinary_maps()
    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == families.ZOT and
            not definition.tags.dummy then
            local context = random_context(401 + #id)
            local builder = grid.new(context)
            local player = {
                branch_id = branches.BRANCH_ZOT,
                depth = 2,
                branch_bottom = 5,
                absolute_depth = 28,
            }
            local okay, result = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(result))
            harness.equal(result.id, id, id .. " retains its source name")
        end
    end
end

-- Source gives this dummy weight 60 to reduce Zot:5 ordinary map density.
-- Selecting it must consume that draw without painting its one-cell MAP or
-- advancing to a different candidate after the no-op.
local function weighted_dummy_is_noop()
    local original = regular.candidates
    local dummy = vaults.get("dummy_balancer_zot")
    local placed = {}
    local fitted = false
    local context = {
        used = {
            add_map = function()
                error("dummy must not enter vault history")
            end,
        },
    }
    local builder = {
        roll = function()
            return 0
        end,
    }

    regular.candidates = function()
        return {
            {
                definition = dummy,
                weight = 60,
            },
        }
    end

    local chosen = regular.place(nil, builder, context, placed,
        function()
            fitted = true
        end)

    regular.candidates = original

    harness.equal(chosen, nil, "dummy consumes the ordinary draw")
    harness.equal(#placed, 0, "dummy leaves no placed map")
    harness.truthy(not fitted, "dummy leaves terrain untouched")
end

-- The mandatory final layout must execute its authored MAP and create one
-- typed Orb record; mere registration would leave Zot:5 unplayable.
local function hall_has_one_orb()
    local definition = layouts.get("hall_of_Zot")
    local result = layouts.execute(random_context(617), definition,
        branches.BRANCH_ZOT, 5)
    local orbs = 0

    for _, record in ipairs(result.records or {}) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == items.ORB_ZOT then
            orbs = orbs + 1
        end
    end

    harness.equal(result.id, "hall_of_Zot", "source final layout runs")
    harness.equal(orbs, 1, "exactly one source Orb is placed")
    harness.truthy(#result.stairs >= 1, "Zot:5 has a connected exit")
end

-- The overgrown stairs need saved start, timer, and target markers at the
-- actual substituted coordinates before a live system can consume them.
local function overgrown_has_trigger_markers()
    local definition = vaults.get("grunt_zot_stairs_overgrown")
    local builder = grid.new(random_context(719))
    local player = {
        branch_id = branches.BRANCH_ZOT,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 28,
    }
    local placed = placement.place(nil, builder, definition, player)
    local counts = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MARKER then
            counts[record.identity] = (counts[record.identity] or 0) + 1
        end
    end

    harness.equal(counts[trigger_ids.ZOT_OVERGROWN_START], 1,
        "one source LOS marker")
    harness.equal(counts[trigger_ids.ZOT_OVERGROWN_TICK], 1,
        "one source turn marker")
    harness.truthy((counts[trigger_ids.ZOT_OVERGROWN_TARGET] or 0) > 0,
        "source plant marker survives substitution")
end

-- Count effective definitions rather than source files so a duplicate NAME
-- cannot silently replace a map and make the inventory appear complete.
local function inventory()
    vaults.load()
    layouts.load()

    local count = 0
    local entries = 0
    local ordinary = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = register.get(categories.VAULTS, id)

        if definition.family == families.ZOT_ENTRY then
            entries = entries + 1
            count = count + 1
        elseif definition.family == families.ZOT then
            ordinary = ordinary + 1
            count = count + 1
        end
    end

    harness.equal(entries, 15, "all source Depths-side Zot entries")
    harness.equal(ordinary, 72,
        "ordinary, style, and weighted dummy source definitions")
    harness.truthy(register.get(categories.LAYOUTS, "hall_of_Zot"),
        "source Zot:5 hall is a registered layout")
    harness.equal(count + 1, 88, "complete source zot.des inventory")
end

-- Source's small entry is retained for inspection but the 14 large
-- primaries own the live Depths:4 weighted gate selection.
local function entry_weights()
    local floor = {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 4,
        branch_bottom = 4,
        absolute_depth = 25,
    }
    local choices = entry.candidates(branches.BRANCH_ZOT, floor)

    harness.equal(#choices, 14, "fourteen active Zot entry maps")

    for _, choice in ipairs(choices) do
        harness.truthy(choice.definition.id ~= "zot_entry_small",
            "inactive source fallback is not drawn")
    end
end

function test.run()
    inventory()
    entry_weights()
    place_ordinary_maps()
    weighted_dummy_is_noop()
    hall_has_one_orb()
    overgrown_has_trigger_markers()

    harness.truthy(layouts.has_explicit(branches.BRANCH_ZOT, 5),
        "Zot:5 has the mandatory authored hall")
end

return test
