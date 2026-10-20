-- Theory of operation: several source overflow maps rename the same terrain
-- features to match their local art. Each .des calls the relevant method at
-- the original source position. The placement engine stores these as typed
-- effects, so inspection and save/restore can retain the authored names.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Gozag's statue art is still granite terrain, but its displayed name is gold.
local function golden_statue(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GOLDEN_STATUE,
    })
end

-- The paired Gozag and Zin vault gives its metal perimeter a silver name.
local function silver_wall(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.METAL_WALL,
        name = names.SILVER_WALL,
    })
end

-- Nemelex's pale crystal wall has a different description from ordinary crystal.
local function white_crystal_wall(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.CRYSTAL_WALL,
        name = names.WHITE_CRYSTAL_WALL,
    })
end

-- Yredelemnul's trees and Hepliaklqana's shrine share the dead-tree name.
local function dead_tree(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

-- The shrine's statue feature depicts an ancestor's gravestone.
local function gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

-- The torment temple uses granite statues as sarcophagi around its altars.
local function sarcophagus(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.SARCOPHAGUS,
    })
end

handler.golden_statue = golden_statue
handler.silver_wall = silver_wall
handler.white_crystal_wall = white_crystal_wall
handler.dead_tree = dead_tree
handler.gravestone = gravestone
handler.sarcophagus = sarcophagus

return handler
