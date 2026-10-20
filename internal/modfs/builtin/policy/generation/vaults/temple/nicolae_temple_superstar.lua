-- Superstar uses the selected count to choose its entrance and decorative
-- punctuation, then opens extra scenery only on the smaller layouts.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- The source groups 6/14, 7/15, and 8/16 by remainder. Keep each group's
-- directives together at the first hook position, before the common SUBST.
local function configure(api)
    local selected = tonumber(count.selected(api))
    local remainder = selected % 4

    if remainder == 2 then
        api:emit(directives.NSUBST, "D = 1:{ / <")
        api:emit(directives.SUBST, "!- = w")
    elseif remainder == 3 then
        api:emit(directives.NSUBST, "D = 1:{ / B")
        api:emit(directives.SUBST, "!- = w")
    else
        api:emit(directives.SUBST, "! = {, - = `")
        api:emit(directives.FTILE, "` = floor_vault")
        api:emit(directives.COLOUR, "` = blue")
    end
end

-- Small layouts need the extra scenic variation before the shared final
-- altar substitution; large layouts leave those glyphs as authored.
local function small_count(api)
    if tonumber(count.selected(api)) < 10 then
        api:emit(directives.SUBST, "EHKM : GGGTTTUVY")
    end
end

handler.configure = configure
handler.small_count = small_count

return handler
