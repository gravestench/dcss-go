-- The Hall is an authored Zot:5 floor. Its DES owns monster, trap, and
-- Orb placement; this Lua validator checks the source path invariant and
-- later the immutable Orb record kept in the save.
local effects = require("constants.vault_effects")
local items = require("ids.items")
local paths = require("policy.generation.vaults.exit_paths")

local hall = {}

-- During placement the resolved cells still carry the Z glyph. Later
-- generation and restore have typed records instead; those must retain
-- exactly one source Orb even after a player picks up the live item.
local function orb_exit(state)
    if state.cells then
        return paths.has_exit_from_glyph(state.cells, "Z")
    end

    local count = 0

    for _, record in ipairs(state.records or state.vault_records or {}) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == items.ORB_ZOT then
            count = count + 1
        end
    end

    if count ~= 1 then
        error("Hall of Zot needs exactly one authored Orb item")
    end

    return true
end

hall.orb_exit = orb_exit

return hall
