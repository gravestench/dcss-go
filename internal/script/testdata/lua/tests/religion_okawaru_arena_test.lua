-- The four source Arena MAPs must all project into a live, enclosed floor.
-- Their special cells drive travel and victory; no duplicate map table is
-- declared in this test.
local generator = require("policy.generation.arena.level")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- One named map at a time makes a malformed layout visible even when the
-- production selector's random draw would rarely choose that map.
function test.run(ctx)
    for number = 1, 4 do
        local id = "okawaru_arena_" .. number
        local staged = generator.generate(ctx, {
            layout_id = id,
            species_id = "SP_HUMAN",
            player_name = "Arena test",
        })
        local level = staged.level
        local sites = staged.portal_data

        harness.equal(level.vault_id, id)
        harness.equal(level.cells[level.entry_y + 1]
            [level.entry_x + 1], terrain.DNGN_STONE_ARCH)
        harness.equal(level.cells[sites.exit_y + 1]
            [sites.exit_x + 1], terrain.DNGN_EXIT_ARENA)
        harness.equal(level.cells[sites.barrier_y + 1]
            [sites.barrier_x + 1],
            terrain.DNGN_CLEAR_PERMAROCK_WALL)
        harness.equal(level.cells[sites.target_y + 1]
            [sites.target_x + 1], terrain.DNGN_FLOOR)
    end
end

return test
