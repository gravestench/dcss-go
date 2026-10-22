-- This authored map has many entrance triggers but one synchronized event.
-- Keep each source glyph as a typed marker so final orientation and save
-- validation can refer to the actual placed cell, not an unrotated MAP.
local effects = require("constants.vault_effects")
local trigger_ids = require("constants.vault_triggers")

local boxes = {}

-- Trigger and disappearing-wall records share one source vault identity.
-- The world trigger owner will link every placed record into one group.
local function markers(api)
    api:record(effects.MARKER, {
        glyph = ":",
        identity = trigger_ids.OSSUARY_BOXES_OPEN,
        group = trigger_ids.OSSUARY_BOXES_GROUP,
        role = "trigger",
    })

    for _, glyph in ipairs({ "a", "b" }) do
        api:record(effects.MARKER, {
            glyph = glyph,
            identity = trigger_ids.OSSUARY_BOXES_WALL,
            group = trigger_ids.OSSUARY_BOXES_GROUP,
            role = "wall",
        })
    end
end

boxes.markers = markers

return boxes
