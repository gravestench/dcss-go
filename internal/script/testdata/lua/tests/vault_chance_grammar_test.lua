-- Source CHANCE clauses use a 10,000-point roll, including decimal percents.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")

local test = {}

-- Parse through the production DES reader so these checks cannot drift from
-- the grammar that will load committed serial maps.
local function vault(id, clause)
    local source = table.concat({
        "NAME: " .. id,
        "DEPTH: D, Depths, Elf, Crypt, Zot, Vaults",
        "CHANCE: " .. clause,
        "MAP",
        "x",
        "ENDMAP",
        "",
    }, "\n")

    return des.parse("vaults/serial/" .. id .. ".des", source)
end

-- A bare chance is the fallback in every eligible branch. Source percent
-- notation and raw rolls both use the same 10,000-point scale.
local function bare_and_raw_chances()
    local bare = vault("bare_chance", "1%")

    harness.equal(depth.chance(bare, branches.BRANCH_DUNGEON, 4), 100,
        "one percent on Dungeon")
    harness.equal(depth.chance(bare, branches.BRANCH_DEPTHS, 2), 100,
        "bare percent on Depths")

    local raw = vault("raw_chance", "8333, 6666 (Zot), 10000 (Vaults)")

    harness.equal(depth.chance(raw, branches.BRANCH_DUNGEON, 4), 8333,
        "raw default chance")
    harness.equal(depth.chance(raw, branches.BRANCH_ZOT, 3), 6666,
        "raw branch override")
    harness.equal(depth.chance(raw, branches.BRANCH_VAULTS, 3), 10000,
        "certain branch override")
end

-- A depth-specific clause overrides the fallback only at that depth; the
-- default still applies elsewhere after the source declaration ends.
local function ranged_decimal_chances()
    local ranged = vault("ranged_chance",
        "0.5% (Depths:1, Elf:1, Crypt), 1%")

    harness.equal(depth.chance(ranged, branches.BRANCH_DEPTHS, 1), 50,
        "half percent at Depths:1")
    harness.equal(depth.chance(ranged, branches.BRANCH_DEPTHS, 2), 100,
        "fallback at Depths:2")
    harness.equal(depth.chance(ranged, branches.BRANCH_CRYPT, 2), 50,
        "half percent throughout Crypt")
    harness.equal(depth.chance(ranged, branches.BRANCH_DUNGEON, 4), 100,
        "fallback in Dungeon")

    local overlapping = vault("overlapping_chance",
        "1% (D:1-5), 2% (D:3-7), 3%")

    harness.equal(depth.chance(overlapping, branches.BRANCH_DUNGEON, 4),
        100, "first matching source range wins")
    harness.equal(depth.chance(overlapping, branches.BRANCH_DUNGEON, 6),
        200, "later range applies outside earlier range")
    harness.equal(depth.chance(overlapping, branches.BRANCH_DUNGEON, 8),
        300, "default applies outside every range")
end

-- No CHANCE declaration means the ordinary map is certain when a caller
-- explicitly asks for it; it does not turn that map into a chance map.
local function missing_and_malformed_chances()
    local ordinary = des.parse("vaults/serial/ordinary.des", table.concat({
        "NAME: ordinary",
        "MAP",
        "x",
        "ENDMAP",
        "",
    }, "\n"))

    harness.equal(depth.chance(ordinary, branches.BRANCH_DUNGEON, 1),
        10000, "no CHANCE declaration")

    for _, clause in ipairs({ "101%", "10001", "0.333%" }) do
        local ok = pcall(vault, "bad_chance", clause)

        harness.falsy(ok, "reject chance outside source roll granularity")
    end
end

-- Run the source grammar cases together because all three forms feed the
-- same selector and should never use different scales.
function test.run()
    bare_and_raw_chances()
    ranged_decimal_chances()
    missing_and_malformed_chances()
end

return test
