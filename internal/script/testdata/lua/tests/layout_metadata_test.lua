-- Layout metadata comes from committed DES files, including disabled maps.
-- These checks use the production parser so the test cannot drift into a
-- second interpretation of DEPTH, WEIGHT, or named script hooks.
local branches = require("ids.branches")
local des = require("policy.generation.vaults.des")
local depth = require("policy.generation.vaults.depth")
local weight = require("policy.generation.vaults.weight")
local directives = require("constants.vault_directives")
local harness = require("tests.harness")

local test = {}

-- Every source layout remains visible to modders, including zero-weight
-- definitions that the ordinary Dungeon selector must never choose.
local function imported_dungeon_layouts()
    local paths = mod.paths("vaults/layout", ".des")
    local active = 0
    local disabled = 0
    local branch_only = 0

    harness.equal(#paths, 23, "total source layout count")

    for _, path in ipairs(paths) do
        local layout = des.parse(path, mod.read(path))
        local dungeon_weight = weight.for_branch(layout,
            branches.BRANCH_DUNGEON)

        harness.truthy(layout.tags.layout, "source layout tag")
        harness.equal(layout.family, "layout", "layout family")

        local dungeon = false

        for level = 1, 15 do
            dungeon = dungeon or depth.eligible(layout,
                branches.BRANCH_DUNGEON, level, 15)
        end

        if not dungeon then
            branch_only = branch_only + 1
        elseif dungeon_weight > 0 then
            active = active + 1
        else
            disabled = disabled + 1
        end
    end

    harness.equal(active, 17, "active Dungeon layouts")
    harness.equal(disabled, 4, "disabled Dungeon layouts")
    harness.equal(branch_only, 2, "Pan-only source layouts")
end

-- Branch clauses override a default weight but must not leak a different
-- branch's weight into the Dungeon draw.
local function source_weight_clauses()
    local function read(id)
        local path = "vaults/layout/" .. id .. ".des"

        return des.parse(path, mod.read(path))
    end

    harness.equal(weight.for_branch(read("layout_basic"),
        branches.BRANCH_DUNGEON), 35, "basic Dungeon weight")
    harness.equal(weight.for_branch(read("layout_basic"),
        branches.BRANCH_SNAKE), 15, "basic Snake weight")
    harness.equal(weight.for_branch(read("layout_rooms"),
        branches.BRANCH_DUNGEON), 15, "rooms Dungeon weight")
    harness.equal(weight.for_branch(read("layout_layer_cave"),
        branches.BRANCH_DUNGEON), 5, "cave default Dungeon weight")
    harness.equal(weight.for_branch(read("layout_layer_cave"),
        branches.BRANCH_SNAKE), 15, "cave Snake override")
    harness.equal(weight.for_branch(read("layout_bigger_room"),
        branches.BRANCH_DUNGEON), 0, "disabled Dungeon weight")
end

-- Invalid weights must fail while loading a mod, before a generated floor
-- happens to choose that layout and advances gameplay randomness.
local function invalid_weight_clauses()
    local site = {
        path = "vaults/layout/bad.des",
        line = 4,
        id = "bad_layout",
    }

    for _, text in ipairs({
        "",
        "-1",
        "1.5",
        "3 (Unknown)",
        "2 (D), 4 (D)",
        "2, 4",
    }) do
        local ok = pcall(weight.parse, text, site)

        harness.falsy(ok, "malformed WEIGHT " .. text)
    end
end

-- Hook-only maps still have source geometry: their run function builds it.
-- Validation hooks are separate so map-size rules can reject bad outputs.
local function named_hook_contract()
    local basic_path = "vaults/layout/layout_basic.des"
    local basic = des.parse(basic_path, mod.read(basic_path))
    local big_path = "vaults/layout/layout_big_octagon.des"
    local big = des.parse(big_path, mod.read(big_path))
    local run = false
    local validate = false

    harness.equal(#basic.rows, 0, "basic layout builds its map in Lua")

    for _, operation in ipairs(basic.operations) do
        run = run or operation.kind == directives.HOOK_RUN
    end

    for _, operation in ipairs(big.operations) do
        validate = validate or
            operation.kind == directives.HOOK_VALIDATE
    end

    harness.truthy(run, "source run hook")
    harness.truthy(validate, "source validation hook")
    harness.falsy(depth.eligible(big, branches.BRANCH_DUNGEON, 8, 15),
        "big octagon starts at D:9")
    harness.truthy(depth.eligible(big, branches.BRANCH_DUNGEON, 9, 15),
        "big octagon includes D:9")
end

-- Run metadata cases together before production catalog integration; this
-- keeps parser failures focused on one owner rather than selection policy.
function test.run()
    imported_dungeon_layouts()
    source_weight_clauses()
    invalid_weight_clauses()
    named_hook_contract()
end

return test
