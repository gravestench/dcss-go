-- Theory of operation: the source's chance-selected builder controller
-- has no geometry. After its own selection, it asks the shared vault
-- placer for one map tagged decor. Selection remains tied to effective
-- catalog tags, so a mod can add a decoration without editing this file.
-- Source: crawl-ref/source/dat/des/builder/decor.des.
local tags = require("constants.vault_tags")

local decor = {}

-- Keep the source's single child request after controller placement;
-- the shared API owns tag eligibility, weighting, and failed geometry.
local function place_decor(api)
    api:place_maps(tags.DECOR, 1)
end

decor.place_decor = place_decor

return decor
