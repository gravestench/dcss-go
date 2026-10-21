-- Pan's demon pit chooses three different tier-two demons. Collected Pan
-- runes shift the source weights toward more dangerous members of the pool.
local directives = require("constants.vault_directives")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Draw by current weight and retire each chosen name, so no pit repeats a
-- tier-two demon. All draws use the vault layout stream supplied by the API.
local function demons(api)
    local runes = api:pan_rune_count()
    local weight_a = 30 - runes * 5
    local weight_b = 20 - runes * 2
    local weight_c = 10 + runes * 2
    local weight_d = 5 + runes
    local choices = {
        {
            name = "hell beast",
            weight = weight_a,
        },

        {
            name = "green death",
            weight = weight_a,
        },

        {
            name = "reaper",
            weight = weight_b,
        },

        {
            name = "lorocyproca",
            weight = weight_b,
        },

        {
            name = "balrug",
            weight = weight_c,
        },

        {
            name = "blizzard demon",
            weight = weight_c,
        },

        {
            name = "hellion",
            weight = weight_d,
        },

        {
            name = "tormentor",
            weight = weight_d,
        },

        {
            name = "cacodemon",
            weight = 5,
        },
    }
    local picked = {}

    for _ = 1, 3 do
        local total = 0

        for _, choice in ipairs(choices) do
            total = total + choice.weight
        end

        local draw = api:roll(total)

        for _, choice in ipairs(choices) do
            draw = draw - choice.weight

            if draw < 0 then
                picked[#picked + 1] = choice.name
                choice.weight = 0

                break
            end
        end
    end

    return table.concat(picked, " / ")
end

-- The leader and transit portal are independent of the three-demon draw.
local function fill_demons(api)
    local lord = "brimstone fiend / ice fiend / tzitzimitl / " ..
        "hell sentinel / demonspawn blood saint w:5 / " ..
        "demonspawn black sun w:5 / demonspawn corrupter w:5 / " ..
        "demonspawn warmonger"

    fill.room(api, demons(api), lord, true)
    api:emit(directives.KITEM, "2 = *")
    api:emit(directives.KFEAT, "2 = transit_pandemonium")
end

room.fill = fill_demons

return room
