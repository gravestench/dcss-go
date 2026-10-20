-- Theory of operation: the same fire temple serves Trog and Makhleb.
-- The overflow scheduler passes the god's selected tag as local map context;
-- a direct, untargeted use keeps the source's mixed altar draw.
local directives = require("constants.vault_directives")
local tags = require("constants.vault_tags")

local handler = {}

-- Bind the altar to the requested god before the map geometry is placed.
local function choose_altar(api)
    local tag = api:map_tag()

    if tag == tags.TEMPLE_OVERFLOW_TROG then
        api:emit(directives.KFEAT, "_ = altar_trog")
    elseif tag == tags.TEMPLE_OVERFLOW_MAKHLEB then
        api:emit(directives.KFEAT, "_ = altar_makhleb")
    else
        api:emit(directives.KFEAT,
            "_ = altar_trog / altar_makhleb")
    end
end

handler.choose_altar = choose_altar

return handler
