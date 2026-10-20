-- Two halves divide this Temple's altar set, leaving one central altar.
-- The source teleporter markers remain in DES beside the authored map.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Choose equal numbers of altars in D and E cells. The Temple catalog
-- selects odd supported counts, so the half count stays integral.
local function configure(api)
    local selected = tonumber(count.selected(api))
    local half = (selected - 1) / 2

    if half % 1 ~= 0 then
        error("divided pantheon requires an odd Temple altar count")
    end

    api:emit(directives.NSUBST,
        "D = " .. half .. ":B / *:'")
    api:emit(directives.NSUBST,
        "E = " .. half .. ":B / *:-")
end

handler.configure = configure

return handler
