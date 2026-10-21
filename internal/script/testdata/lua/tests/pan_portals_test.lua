-- Pan source KFEAT names must decode to live portal grid features. Their
-- distinct IDs let command policy choose entry, transit, or exit behavior.
local features = require("content.terrain_features")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}

-- Check the four source portal names used by Pan maps and hooks.
function test.run()
    local names = {
        enter_pandemonium = terrain.DNGN_ENTER_PANDEMONIUM,
        transit_pandemonium = terrain.DNGN_TRANSIT_PANDEMONIUM,
        exit_pandemonium = terrain.DNGN_EXIT_PANDEMONIUM,
        exit_through_abyss = terrain.DNGN_EXIT_THROUGH_ABYSS,
    }

    for name, feature in pairs(names) do
        harness.equal(features.named_vault_terrain[name], feature,
            "Pan source feature " .. name)

        -- A KFEAT record must paint the live grid, not remain a pending
        -- annotation that command policy cannot inspect at the portal cell.
        local cells = { { "DNGN_FLOOR" } }
        local records = {
            {
                kind = effects.FEATURE,
                identity = name,
                x = 0,
                y = 0,
                pending = true,
            },
        }
        local retained = features.apply_vault_terrain(cells, records)

        harness.equal(cells[1][1], feature, "placed Pan portal " .. name)
        harness.equal(#retained, 0, "placed Pan portal record " .. name)
    end
end

return test
