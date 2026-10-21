-- Profane Halls changes its doors, defenders, and final child when the
-- source Zot entrance is scheduled on this floor. Each method sits at the
-- original DES script position, so later source substitutions see it.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local tags = require("constants.vault_tags")

local handler = {}

-- A Zot floor seals the shuffled portal slots into guardian positions;
-- otherwise the source shuffles the door/loot alternatives.
local function zot_shape(api)
    if api:branch_entry(branches.BRANCH_ZOT) then
        api:emit(directives.SUBST, "}])> = G")
    else
        api:emit(directives.SHUFFLE, "}])>")
    end
end

-- Zot changes the D slot into one of four dragon guardians. Other Depths
-- floors keep the source's ordinary monster band in that slot.
local function zot_monsters(api)
    if api:branch_entry(branches.BRANCH_ZOT) then
        api:emit(directives.NSUBST,
            "D = 1:K / 1:L / 1:M / 1:N")
        api:emit(directives.KMONS, "K = storm dragon")
        api:emit(directives.KMONS, "L = shadow dragon")
        api:emit(directives.KMONS, "M = quicksilver dragon")
        api:emit(directives.KMONS, "N = golden dragon")

        return
    end

    api:emit(directives.KMONS, "D = 8 band")
end

-- The H chamber is a real Zot gate only on the scheduled entry floor.
-- On another floor it is a weighted loot chamber instead.
local function zot_child(api)
    local tag = tags.GRUNT_PROFANE_LOOT

    if api:branch_entry(branches.BRANCH_ZOT) then
        tag = tags.GRUNT_ZOT_PORTAL
    end

    api:emit(directives.SUBVAULT, "H : " .. tag)
end

handler.zot_shape = zot_shape
handler.zot_monsters = zot_monsters
handler.zot_child = zot_child

return handler
