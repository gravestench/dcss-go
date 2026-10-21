-- Theory of operation: every source end quadrant uses the same loot and
-- rune choices at its own DES source position. These functions emit source
-- directives, while each quadrant keeps its own authored geometry in DES.
-- Composition history is local to one floor and enforces a single real rune.
local directives = require("constants.vault_directives")
local tags = require("constants.vault_tags")

local handler = {}

-- The three substitutions reproduce the source's nested loot odds.
-- Later substitutions operate on glyphs produced by earlier ones.
local function loot(api)
    api:emit(directives.SUBST, "? = | * .:43")
    api:emit(directives.SUBST, "| = | *:2")
    api:emit(directives.SUBST, "* = * |:2")
end

-- A prize quadrant gets a one-in-four first chance. If it declines, the
-- first ordinary quadrant with a rune slot supplies the real silver rune.
-- Once a real-rune child succeeds, later slots become no-rune rewards.
local function rune(api)
    local available = not api:has_placed_tag(tags.VAULTS_END_RUNE)
    local prize = api:has_tag(tags.VAULTS_END_QUADRANT_PRIZE)
    local ordinary = api:has_tag(tags.VAULTS_END_QUADRANT) or
        api:has_tag(tags.VAULTS_END_ROOM_RUNE)
    local real = available and
        ((prize and api:one_in(4)) or ordinary)
    local selected = real and tags.VAULTS_END_RUNE or
        tags.VAULTS_END_NORUNE

    api:emit(directives.SUBVAULT, "O : " .. selected)
end

handler.loot = loot
handler.rune = rune

return handler
