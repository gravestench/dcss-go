-- Entity specs report missing source paths instead of fabricating a definition.

local harness = require("tests.harness")
local monster = require("policy.generation.vaults.specs.monster")
local item = require("policy.generation.vaults.specs.item")
local choice = require("policy.generation.vaults.specs.choice")

local test = {}

local site = {
    path = "vaults/arrival/kb_arrival_jail.des",
    vault_id = "kb_arrival_jail",
    line = 26,
    directive = "KMONS",
    glyph = "O",
}

-- Comma slots and slash alternatives retain separate monster and gear choices.
local function parser_keeps_slots_and_equipment()
    local slots = monster.parse(
        "human / elf / orc; nothing|stone.mace / naga; nothing, vampire spells:.",
        site
    )

    harness.equal(#slots, 2, "comma slots")
    harness.equal(#slots[1], 4, "monster alternatives")
    harness.equal(slots[1][3].name, "orc", "third monster")
    harness.equal(slots[1][3].equipment[1][1], "nothing", "first gear choice")
    harness.equal(slots[1][3].equipment[1][2], "stone", "second gear choice")
    harness.equal(slots[1][3].equipment[2][1], "mace", "second gear slot")
    harness.equal(slots[2][1].spells[1], ".", "empty spellbook override")
end

-- "nothing" is a typed no-spawn alternative even with weighted modifiers.
local function parser_reads_modifiers_and_no_spawn()
    local monsters = monster.parse(
        "w:30 nothing / fungus col:yellow att:neutral place:D:1 / 0",
        site
    )[1]

    harness.truthy(monsters[1].no_spawn, "nothing result")
    harness.equal(monsters[1].weight, 30, "prefix weight")
    harness.equal(monsters[2].colour, "yellow", "colour")
    harness.equal(monsters[2].attitude, "neutral", "attitude")
    harness.equal(monsters[2].place, "D:1", "place")
    harness.equal(monsters[3].name, "0", "source random monster")

    local items = item.parse("stone q:4 / w:5 nothing, place:D:1 skeleton", site)

    harness.equal(#items, 2, "item slots")
    harness.equal(items[1][1].quantity, 4, "item quantity")
    harness.equal(items[1][2].weight, 5, "item choice weight")
    harness.truthy(items[1][2].no_spawn, "item nothing result")
    harness.equal(items[2][1].place, "D:1", "item place")
end

-- Cumulative weights determine the selected source alternative at boundaries.
local function source_cumulative_choice_sequence()
    local draws = { 0, 0, 13 }
    local bounds = { 10, 20, 30 }
    local index = 0
    local random = {}

    -- Check each cumulative source bound while returning the scripted draw.
    function random:roll(bound)
        index = index + 1
        harness.equal(bound, bounds[index], "cumulative bound")

        return draws[index]
    end

    local alternatives = monster.parse("rat / bat / goblin", site)[1]
    local picked = choice.pick(random, alternatives)

    harness.equal(index, 3, "source draws once per alternative")
    harness.equal(picked.name, "bat", "last accepted cumulative draw")
end

-- Bad terms identify the originating DES line for mod authors.
local function malformed_terms_name_the_source()
    local cases = {
        { parser = monster, expression = "rat w:0" },
        { parser = monster, expression = "rat bogus:3" },
        { parser = item, expression = "stone q:bad" },
        { parser = item, expression = "stone unknown:4" },
    }

    for _, case in ipairs(cases) do
        local ok, message = pcall(case.parser.parse, case.expression, site)

        harness.falsy(ok, "malformed expression accepted")
        harness.truthy(message:find(site.path, 1, true), "missing source path")
        harness.truthy(message:find(site.vault_id, 1, true), "missing vault ID")
        harness.truthy(message:find(case.expression, 1, true), "missing expression")
    end
end

-- Cover slots, modifiers, weighted choices, and DES-site errors in the parser.
function test.run()
    parser_keeps_slots_and_equipment()
    parser_reads_modifiers_and_no_spawn()
    source_cumulative_choice_sequence()
    malformed_terms_name_the_source()
end

return test
