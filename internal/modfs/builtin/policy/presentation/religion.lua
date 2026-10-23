-- Worship display reads the one saved ECS owner each time the game redraws.
-- The catalog supplies names and piety mode; no Go-side god list is needed.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local modes = require("constants.god_piety_modes")
local names = require("policy.religion.names")
local piety = require("policy.religion.piety")
local descriptions = require("policy.religion.conduct.description")

local religion = {}

-- Project a patron's current devotion into the six source HUD positions.
-- Gozag has no ordinary piety scale; penance remains separately visible.
function religion.run(ctx)
    local player = ctx:player()
    local state = player and ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id == gods.NO_GOD then
        return {
            god_name = "",
            piety_stars = "",
            penance = 0,
            likes = {},
            dislikes = {},
        }
    end

    local definition = catalog.get(categories.GODS, state.god_id)
    local stars = ""
    local conduct_text = descriptions.for_god(state.god_id)

    if definition.piety_mode == modes.XOM then
        local rank = piety.rank(state.god_id, state.piety)

        stars = string.rep(".", rank - 1) .. "*" ..
            string.rep(".", 6 - rank)
    elseif definition.piety_mode ~= modes.NONE then
        local rank = piety.rank(state.god_id, state.piety)

        stars = string.rep("*", rank) .. string.rep(".", 6 - rank)
    end

    return {
        god_name = names[state.god_id],
        piety_stars = stars,
        penance = state.penance[state.god_id] or 0,
        likes = conduct_text.likes,
        dislikes = conduct_text.dislikes,
    }
end

register.policy({
    id = "presentation.religion",
    run = religion.run,
})

return religion
