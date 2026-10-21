-- Theory of operation: the source MAP fixes the entire Slime:5 floor.
-- Its old inline Lua attached a death callback to the Royal Jelly and a
-- level-entry trigger to the central altar. The named DES hook retains
-- those source sites as typed markers; Lua ECS policy owns the live seal.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local item_ids = require("ids.items")
local monster_ids = require("ids.monsters")
local names = require("constants.slime_pit")

local layout = {}

-- Keep the old callback locations visible in the saved source record list.
-- The death policy recognizes the Royal Jelly through its vault origin.
function layout.mark(api)
    api:emit(directives.MARKER,
        "1 = " .. names.ROYAL_JELLY_MARKER)
    api:emit(directives.MARKER,
        "Z = " .. names.FIXUP_MARKER)
    -- Terrain projection drops unchanged source-feature records. A keyed
    -- marker keeps each final n wall's authorship for ECS and save checks.
    api:emit(directives.MARKER,
        "n = " .. names.SEAL_MARKER)
end

-- One historical rune and its Royal Jelly must belong to the authored
-- layout. The first DES placement pass passes only cells; the later layout
-- and save passes supply the resolved records checked here.
function layout.validate(input)
    local records = input.records or input.vault_records

    if not records then
        return true
    end

    local runes = 0
    local rune_owner
    local guardians = 0

    for _, record in ipairs(records) do
        local arguments = record.arguments or {}
        local owner = record.source_id or record.vault_id

        if record.kind == effects.ITEM and
            arguments.kind_id == item_ids.RUNE_SLIME and
            not arguments.mimic then
            runes = runes + 1
            rune_owner = owner
        elseif owner == names.MAP_ID and
            record.kind == effects.MONSTER and
            arguments.kind_id == monster_ids.MONS_ROYAL_JELLY then
            guardians = guardians + 1
        end
    end

    if runes ~= 1 or rune_owner ~= names.MAP_ID or guardians ~= 1 then
        error("Slime end needs one source Royal Jelly and slimy rune" ..
            " (runes " .. runes .. ", guardians " .. guardians .. ")")
    end

    return true
end

return layout
