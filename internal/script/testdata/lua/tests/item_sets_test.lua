-- Character creation picks one item from each of four mutually exclusive
-- sets; the saved choices gate eligibility without consuming RNG on reload.

local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local sets = require("constants.item_sets")

local test = {}

-- Record every item-generation draw so a second initialise call cannot hide
-- a reroll that happened to choose the same first entries.
local function context()
    local state = {
        components = {},
        draws = 0,
    }

    -- Expose component presence to the real item-set initializer while
    -- keeping the fixture limited to the state that initializer uses.
    function state:has(_, name)
        return self.components[name] ~= nil
    end

    -- Read the stored set choice on later initialization, proving it is
    -- reused rather than selected a second time.
    function state:get(_, name)
        return self.components[name]
    end

    -- Capture the chosen set as persistent component data so the test can
    -- inspect it after the production initializer returns.
    function state:add(_, name, value)
        self.components[name] = value
    end

    -- Count set-selection draws on the item stream and reject empty bounds;
    -- a saved choice should prevent this method from running again.
    function state:random(stream, bound)
        harness.equal(stream, "item_generation", "named set RNG stream")
        harness.truthy(bound > 0, "positive set size")
        self.draws = self.draws + 1

        return 0
    end

    return state
end

-- Zero draws choose the first ID in each distinct set; an unchosen wand in
-- the same set must remain unavailable to generation.
local function chosen_once_and_saved()
    local ctx = context()
    local player = 1

    item_sets.initialise(ctx, player)

    local saved = ctx:get(player, component.PLAYER_ITEM_SETS)

    harness.equal(ctx.draws, 4, "four independent set draws")
    harness.equal(saved.choices[sets.HEX_WANDS],
        ids.WAND_CHARMING, "first hex wand")
    harness.equal(saved.choices[sets.BEAM_WANDS],
        ids.WAND_ACID, "first beam wand")
    harness.equal(saved.choices[sets.BLAST_WANDS],
        ids.WAND_ICEBLAST, "first blast wand")
    harness.equal(saved.choices[sets.CONCEALMENT_SCROLLS],
        ids.SCR_FOG, "first concealment scroll")
    harness.falsy(item_sets.allowed(ctx, player, ids.WAND_PARALYSIS),
        "unselected hex wand excluded")
    harness.truthy(item_sets.allowed(ctx, player, ids.WAND_CHARMING),
        "selected hex wand allowed")

    -- Reusing the persisted component must not advance the RNG stream.
    item_sets.initialise(ctx, player)

    harness.equal(ctx.draws, 4, "saved sets never redraw")
end

-- Reinitialize the same fixture to verify the chosen appearance set is
-- durable and does not consume a fresh random draw.
function test.run()
    chosen_once_and_saved()
end

return test
