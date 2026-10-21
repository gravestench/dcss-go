-- The committed Vaults:$ DES corpus is authoritative for all source
-- quadrants. Loading it also validates each named Lua handler at boot.
local categories = require("constants.catalog")
local harness = require("tests.harness")
local layouts = require("policy.generation.layouts.catalog")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Count source roles by their registered tags instead of file discovery order.
-- One map may carry both ordinary and mall tags, so overlaps are deliberate.
function test.run()
    vaults.load()
    layouts.load()

    local main = layouts.get("vaults_vault")
    local regular = 0
    local prize = 0
    local mall = 0
    local room = 0
    local rune_helpers = 0
    local total = 0

    harness.equal(#main.places, 1, "one explicit Vaults end place")

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "vaults_end" then
            local map = definition
            total = total + 1

            if map.tags.vaults_end_quadrant then
                regular = regular + 1
            end

            if map.tags.vaults_end_quadrant_prize then
                prize = prize + 1
            end

            if map.tags.vaults_end_quadrant_mall or
                map.tags.vaults_end_quadrant_prize_mall then
                mall = mall + 1
            end

            if id:match("^vaults_end_room_") then
                room = room + 1
            end

            if id == "vaults_end_rune" or id == "vaults_end_norune" or
                id == "vaults_end_rune_mimic" then
                rune_helpers = rune_helpers + 1
            end
        end
    end

    harness.equal(total, 72, "source end helpers")
    harness.equal(regular, 40, "ordinary quadrants")
    harness.equal(prize, 25, "prize quadrants")
    harness.equal(mall, 4, "mall overlaps")
    harness.equal(room, 4, "inner room helpers")
    harness.equal(rune_helpers, 3, "rune location helpers")
end

return test
