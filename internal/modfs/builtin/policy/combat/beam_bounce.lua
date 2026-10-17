local flavours = require("constants.beam_flavours")
local terrain = require("constants.terrain")

local bounce = {}

local tree_or_edge = {
    [terrain.DNGN_OPEN_SEA] = true,
    [terrain.DNGN_LAVA_SEA] = true,
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
    [terrain.DNGN_PETRIFIED_TREE] = true,
}

-- beam.cc:bolt::is_bouncy applies these rules to both monster and player
-- rays. The trajectory service calls this only after hitting solid terrain.
function bounce.crystal(feature_id)
    return feature_id ~= nil and not tree_or_edge[feature_id]
end

function bounce.electric(feature_id)
    return bounce.crystal(feature_id) and
        feature_id ~= terrain.DNGN_METAL_WALL and
        feature_id ~= terrain.DNGN_GRATE
end

function bounce.for_profile(profile, options)
    if options and options.bounceable == false then
        return nil
    end

    if profile.flavour == flavours.BEAM_CRYSTAL then
        return bounce.crystal
    end

    if profile.flavour == flavours.BEAM_ELECTRICITY then
        return bounce.electric
    end

    return nil
end

return bounce
