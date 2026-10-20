-- Variable Temple maps substitute exactly the count chosen for this run.
-- A missing plan is an error because a fallback would change the map and
-- god partition without updating the saved Temple selection.
local settings = require("constants.temple_settings")

local count = {}

-- Return the source string form used by NSUBST count expressions. The
-- Temple plan validator later proves this value is eligible for the map.
function count.selected(api)
    local value = api:setting(settings.ALTAR_COUNT)

    if type(value) ~= "number" or value % 1 ~= 0 then
        error("Temple map needs the selected altar count")
    end

    return tostring(value)
end

return count
