local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local sets = require("constants.item_sets")

local test = {}

local function context()
    local state = {
        components = {},
        draws = 0,
    }

    function state:has(_, name)
        return self.components[name] ~= nil
    end

    function state:get(_, name)
        return self.components[name]
    end

    function state:add(_, name, value)
        self.components[name] = value
    end

    function state:random(stream, bound)
        harness.equal(stream, "item_generation", "named set RNG stream")
        harness.truthy(bound > 0, "positive set size")
        self.draws = self.draws + 1

        return 0
    end

    return state
end

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

    item_sets.initialise(ctx, player)

    harness.equal(ctx.draws, 4, "saved sets never redraw")
end

function test.run()
    chosen_once_and_saved()
end

return test
