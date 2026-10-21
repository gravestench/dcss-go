-- Theory of operation: A fully open seed lets inserted rooms become the city buildings.
-- The DES declaration owns selection; this hook paints the seed.
local build = require("policy.generation.layouts.vaults.build")
local motif = require("policy.generation.layouts.vaults.boxes")

local layout = {}

-- Start with open floor so source room maps form obstacles and
-- the shared connector pass gives them reachable entrances.
local function layout_vaults_chaotic_city(api)
    return build.run(api, motif.chaotic_city)
end

layout.layout_vaults_chaotic_city = layout_vaults_chaotic_city

return layout
