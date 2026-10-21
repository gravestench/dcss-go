-- Vaults layout policy chooses the entry wall for each room. The ordinary
-- random floating placer must therefore accept a checked exact origin when
-- used by the room owner, without changing ordinary minivault behavior.
local des = require("policy.generation.vaults.des")
local branches = require("ids.branches")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local rooms = require("policy.generation.layouts.vaults.rooms")

local test = {}

-- Provide the same bounded random source as generation while keeping the
-- fixture independent of a particular seed or unrelated vault selection.
local function context()
    local fixture = {}

    function fixture:random_u64()
        return 0, 0
    end

    return fixture
end

-- A parsed DES fixture exercises the same orientation and origin path as
-- committed room maps, so future parser changes remain visible here.
local function room()
    return des.parse("vaults/vaults_room/fit_probe.des", table.concat({
        "NAME: fit_probe",
        "MAP",
        "...",
        ".+.",
        "...",
        "ENDMAP",
    }, "\n"))
end

-- Exact room placement must be deterministic and reject protected source
-- cells before writing any terrain or records to the builder.
function test.run()
    local builder = grid.new(context())
    local definition = room()
    local placed = placement.place(nil, builder, definition, nil, {
        left = 10,
        top = 12,
        turns = 0,
    })

    harness.equal(placed.bounds.x, 10, "room respects chosen x origin")
    harness.equal(placed.bounds.y, 12, "room respects chosen y origin")
    harness.equal(builder:cell(11, 13), "+", "room draws at exact position")

    local protected = {
        ["30:31"] = true,
    }
    local blocked = pcall(placement.place, nil, builder, definition, nil, {
        left = 30,
        top = 31,
        turns = 0,
        protected = protected,
    })

    harness.falsy(blocked, "protected room fit is rejected")
    harness.equal(builder:cell(30, 31), "#",
        "rejected fit does not alter the builder")

    local ids = rooms.ids("vaults_room")

    harness.truthy(#ids > 0, "source standard rooms join tagged selection")

    for index = 2, #ids do
        harness.truthy(ids[index - 1] < ids[index],
            "room IDs remain independent of file load order")
    end

    local selected = rooms.choose(builder, "vaults_empty", {
        branch_id = branches.BRANCH_VAULTS,
        depth = 1,
        branch_bottom = 5,
        absolute_depth = 14,
        layout_family = "vaults",
    })

    harness.truthy(selected and selected.tags.vaults_empty,
        "Vaults room selection uses source tag eligibility")

    local before = builder:cell(40, 40)
    local rejected = rooms.place(nil, builder, "vaults_room_hallway", {
        x = 40,
        y = 40,
    }, 0, {
        ["40:40"] = true,
    })

    harness.falsy(rejected, "occupied source room is vetoed")
    harness.equal(builder:cell(40, 40), before,
        "vetoed tagged room leaves the builder unchanged")

    local fitted = rooms.place(nil, builder, "vaults_room_hallway", {
        x = 50,
        y = 50,
    }, 0)

    harness.equal(fitted.id, "vaults_room_hallway",
        "fitted room retains its authored source ID")
    harness.equal(fitted.bounds.x, 50, "room transaction uses exact x")
    harness.equal(builder:cell(51, 51), ".",
        "successful room transaction publishes carved terrain")
end

return test
