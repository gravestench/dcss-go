-- Entity specs report missing source paths instead of fabricating a definition.

local harness = require("tests.harness")
local monster = require("policy.generation.vaults.specs.monster")
local item = require("policy.generation.vaults.specs.item")
local choice = require("policy.generation.vaults.specs.choice")
local resolve = require("policy.generation.vaults.specs.resolve")
local enchantments = require("constants.vault_monster_enchantments")

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

-- Source DES marks an individual actor as patrolling and may ask for a
-- random floor monster by name. Both must survive parsing as separate intent.
local function parser_reads_patrol_and_random_request()
    local selected = monster.parse("patrolling quokka", site)[1][1]

    harness.equal(selected.name, "quokka", "patrol is not part of the name")
    harness.truthy(selected.patrolling, "authored patrol intent")

    local awake = monster.parse("generate_awake quokka", site)[1][1]

    harness.truthy(awake.generate_awake,
        "authored awake modifier is separate from the monster name")

    local random = monster.parse("random", site)[1][1]

    resolve.validate_monster(random, site)
    harness.equal(random.name, "random", "source random request")
end

-- Authored identity, strength, art, and permanent status are independent
-- of the monster species and must be retained for the live actor runtime.
local function parser_reads_actor_overrides()
    local selected = monster.parse(
        "statue name:charred name_adjective tile:mons_statue_mage " ..
        "hp:12 hd:3 perm_ench:slow dbname:vehumet_statue",
        site
    )[1][1]

    harness.equal(selected.name, "statue", "species name")
    harness.equal(selected.custom_name, "charred", "authored display name")
    harness.truthy(selected.name_adjective, "name grammar")
    harness.equal(selected.tile, "mons_statue_mage", "authored tile")
    harness.equal(selected.hp, 12, "fixed hit points")
    harness.equal(selected.hd, 3, "fixed hit dice")
    harness.equal(selected.permanent_enchantments[1], enchantments.SLOW,
        "permanent source enchantment")
    harness.equal(selected.database_name, "vehumet statue",
        "source database alias")
end

-- Repeated spells: tags are source alternative books; semicolons stay inside
-- one book as distinct slots. Reject a bad slot at the authored DES site.
local function parser_keeps_spellbooks()
    local selected = monster.parse(
        "rat spells:throw_flame.53.magical " ..
        "spells:throw_frost.22.natural",
        site
    )[1][1]

    harness.equal(#selected.spells, 2, "alternative source books")
    harness.equal(selected.spells[1], "throw_flame.53.magical",
        "first source book")
    harness.equal(selected.spells[2], "throw_frost.22.natural",
        "second source book")

    local equipped = monster.parse(
        "rat spells:throw_flame.53.magical;throw_frost.22.natural ; spear",
        site
    )[1][1]

    harness.equal(equipped.spells[1],
        "throw_flame.53.magical;throw_frost.22.natural",
        "semicolon separates spell slots before gear")
    harness.equal(equipped.equipment[1][1], "spear",
        "equipment separator remains after spell extraction")

    local random = {}

    function random:random(_, bound)
        harness.equal(bound, 2, "one source book choice")

        return 1
    end

    local resolved = resolve.monster(random, selected, 4, site)

    harness.equal(resolved.spells[1], selected.spells[2],
        "source chooses the second complete book")

    local okay, reason = pcall(monster.parse,
        "rat spells:throw_flame.bad.magical", site)

    harness.falsy(okay, "invalid source spell frequency accepted")
    harness.truthy(reason:find(site.path, 1, true),
        "spell error lacks DES source path")
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
    parser_reads_patrol_and_random_request()
    parser_reads_actor_overrides()
    parser_keeps_spellbooks()
    source_cumulative_choice_sequence()
    malformed_terms_name_the_source()
end

return test
