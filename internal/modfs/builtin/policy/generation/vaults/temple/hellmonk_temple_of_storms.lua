-- The storm Temple usually makes a thunder fog marker; one in twenty-five
-- versions instead puts a diamond obelisk at the same authored cell.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Choose the J-cell feature before count substitutions. The selected
-- marker becomes a saved cloud source when the Temple is populated.
local function choose_storm(api)
    if api:roll(25) == 0 then
        api:emit(directives.KMONS, "J = diamond obelisk")

        return
    end

    api:emit(directives.MARKER,
        'J = lua:fog_machine { cloud_type = "thunder", ' ..
        'pow_min = 30, pow_max = 50, delay = 5, start_clouds = 3, ' ..
        'size = 4, walk_dist = 1, spread_rate = 100, excl_rad = 0 }')
end

-- Select the authored altar arrangement, leaving the unchosen lettered
-- cells as the storm Temple's decorative terrain.
local function choose_altars(api)
    local selected = tonumber(count.selected(api))

    if selected == 7 then
        api:emit(directives.SUBST, "DE = B, FHI:G.")
    elseif selected == 8 then
        api:emit(directives.SUBST, "FH = B, DEI:G.")
    elseif selected == 11 then
        api:emit(directives.SUBST, "DFH = B, EI:G.")
    elseif selected == 15 then
        api:emit(directives.SUBST, "DEFH = B, I:G.")
    else
        api:emit(directives.SUBST, "DEFHI = B")
    end
end

handler.choose_storm = choose_storm
handler.choose_altars = choose_altars

return handler
