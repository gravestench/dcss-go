-- The rare empty Temple has no ordinary god altar. Its defaced scenery
-- and first-entry message explain why this map feels abandoned.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local messages = require("constants.temple_messages")

local handler = {}

-- Attach the source names to their feature kinds so inspection can show
-- the same ruined pillar and carved wall descriptions after restore.
local function feature_names(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.BROKEN_PILLAR,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_WALL,
        name = names.DEFACED_CARVED_STONE_WALL,
    })
end

-- Preserve the source epilogue as a typed, one-time entry message. The
-- Temple presentation path can display it without rerunning map generation.
local function epilogue(api)
    api:record(effects.ENTRY_MESSAGE, {
        text = messages.FORGOTTEN_AIR,
    })
end

handler.feature_names = feature_names
handler.epilogue = epilogue

return handler
