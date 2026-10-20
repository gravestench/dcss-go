-- Theory of operation: the open layout offers eight shuffled letter sites.
-- A count-specific pattern spreads selected B altars around the centre and
-- erases the unused letters before the source's G decoration is substituted.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local chosen_sites = {
    "d", "dh", "dgi", "dfhj", "dfgij", "defhij", "defghij",
    "defghijk",
}
local unused_sites = {
    "efghijk", "efgijk", "efhjk", "egik", "ehk", "gk", "k",
}

local handler = {}

-- The map's advertised tags start at two, but source Lua also defines the
-- one-altar arrangement; retain it for future tags or direct map requests.
local function arrange_altars(api)
    local selected = count.selected(api, 1, 8)

    api:emit(directives.SUBST, chosen_sites[selected] .. " = B")

    if unused_sites[selected] then
        api:emit(directives.SUBST, unused_sites[selected] .. " = .")
    end
end

handler.arrange_altars = arrange_altars

return handler
