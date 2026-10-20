-- Source WEIGHT groups choose the first matching depth range before default.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local weight = require("policy.generation.vaults.weight")
local harness = require("tests.harness")

local test = {}

-- Exercise real DES parsing rather than rebuilding the production weight
-- schema in a test fixture.
local function vault(id, declarations)
    local source = {
        "NAME: " .. id,
        "DEPTH: D, Orc, Elf, Lair, Depths",
    }

    for _, declaration in ipairs(declarations) do
        source[#source + 1] = "WEIGHT: " .. declaration
    end

    source[#source + 1] = "MAP"
    source[#source + 1] = "x"
    source[#source + 1] = "ENDMAP"
    source[#source + 1] = ""

    return des.parse("vaults/builder/" .. id .. ".des",
        table.concat(source, "\n"))
end

-- A source room can give a grouped branch/depth range one weight and use a
-- later bare clause only where no specific range matches.
local function depth_groups_and_default()
    local room = vault("weighted_room", {
        "59 (D:8-12, Orc), 40 (D:13-, Elf:1), 32",
    })

    harness.equal(weight.for_branch(room, branches.BRANCH_DUNGEON, 7),
        32, "early Dungeon default")
    harness.equal(weight.for_branch(room, branches.BRANCH_DUNGEON, 8),
        59, "first Dungeon range")
    harness.equal(weight.for_branch(room, branches.BRANCH_DUNGEON, 13),
        40, "later Dungeon range")
    harness.equal(weight.for_branch(room, branches.BRANCH_ORC, 2),
        59, "grouped Orc weight")
    harness.equal(weight.for_branch(room, branches.BRANCH_ELF, 1),
        40, "Elf first depth")
    harness.equal(weight.for_branch(room, branches.BRANCH_ELF, 2),
        32, "Elf later default")
end

-- A missing default is zero, and an unspaced branch clause is still source
-- syntax. Multiple WEIGHT rows retain the first matching range.
local function zero_and_multiple_rows()
    local disabled = vault("disabled_room", { "0 (D), 100 (Lair)" })

    harness.equal(weight.for_branch(disabled, branches.BRANCH_DUNGEON, 4),
        0, "explicit zero Dungeon weight")
    harness.equal(weight.for_branch(disabled, branches.BRANCH_DEPTHS, 1),
        0, "unlisted branch has zero default")

    local compact = vault("compact_room", { "5, 15(Lair)" })

    harness.equal(weight.for_branch(compact, branches.BRANCH_DUNGEON, 4),
        5, "bare source weight")
    harness.equal(weight.for_branch(compact, branches.BRANCH_LAIR, 2),
        15, "unspaced Lair override")

    local repeated = vault("repeated_room", {
        "5 (D:1-5), 9 (D:3-7)",
        "2",
    })

    harness.equal(weight.for_branch(repeated, branches.BRANCH_DUNGEON, 4),
        5, "first matching range wins")
    harness.equal(weight.for_branch(repeated, branches.BRANCH_DUNGEON, 6),
        9, "second range applies outside first")
    harness.equal(weight.for_branch(repeated, branches.BRANCH_DUNGEON, 8),
        2, "later bare default persists")
end

-- Reject a malformed grouped clause while reporting its authored DES site.
local function malformed_weight()
    local ok, message = pcall(vault, "bad_weight", { "5 (D:1-3" })

    harness.falsy(ok, "unbalanced WEIGHT group fails")
    harness.truthy(tostring(message):find("bad_weight.des", 1, true),
        "weight error names its DES file")
end

-- Cover all source forms together so the shared parser and resolver cannot
-- disagree about clause order.
function test.run()
    depth_groups_and_default()
    zero_and_multiple_rows()
    malformed_weight()
end

return test
