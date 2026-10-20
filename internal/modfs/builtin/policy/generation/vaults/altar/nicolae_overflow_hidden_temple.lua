-- Theory of operation: the hidden temple has five candidate letter sites.
-- The chosen count makes some sites altars and some stone decoration; the
-- three-altar layout shuffles two pairs before applying those assignments.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local altar_sites = {
    "c", "bd", "cbd", "abde", "abcde",
}
local stone_sites = {
    "abde", "ace", "ae", "c",
}

local handler = {}

-- Emit the shuffle first so the subsequent site assignments refer to the
-- same transformed letters as the source's three-god arrangement.
local function arrange_altars(api)
    local selected = count.selected(api, 1, 5)

    if selected == 3 then
        api:emit(directives.SHUFFLE, "ae/bd")
    end

    api:emit(directives.SUBST, altar_sites[selected] .. " = B")

    if stone_sites[selected] then
        api:emit(directives.SUBST, stone_sites[selected] .. " = G")
    end
end

handler.arrange_altars = arrange_altars

return handler
