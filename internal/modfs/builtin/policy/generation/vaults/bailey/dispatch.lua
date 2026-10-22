-- Theory of operation: the source `bailey` definition has no MAP rows.
-- Its post-place hook looks up the saved weapon theme and asks the normal
-- tagged vault selector to place one matching child. The controller ID
-- remains in history, while the child supplies all floor geometry.
local bailey = require("constants.bailey")

local dispatch = {}

-- A normal game must arrive with the entrance's saved theme. The source
-- Wizmode fallback is intentionally absent, because redrawing the theme
-- here could send a saved axe gate to a polearm layout after restore.
local function run(api)
    local theme = api.context.bailey_theme
    local tag

    if theme == bailey.AXE then
        tag = bailey.AXE_TAG
    elseif theme == bailey.POLEARM then
        tag = bailey.POLEARM_TAG
    else
        error("Bailey dispatcher has no valid saved weapon theme")
    end

    local count, ids = api:place_maps(tag, 1, {
        family = "bailey",
    })

    if count ~= 1 then
        error("Bailey has no eligible " .. tag .. " layout")
    end

    return ids[1]
end

dispatch.run = run

return dispatch
