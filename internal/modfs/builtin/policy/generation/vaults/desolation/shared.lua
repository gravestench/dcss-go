-- Theory of operation: the three complete floors own their MAP geometry
-- in DES. These small hooks preserve the source border, statue name, and
-- optional temple shuffle at their source positions. Fog, rewards, and
-- nested ruin slots remain explicit DES directives.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local fill = require("constants.vault_border_fill")
local names = require("constants.vault_feature_names")

local shared = {}

-- Outer unused canvas cells look like the infinite salt plain; the
-- saved grid still distinguishes walkable interior from its border.
function shared.border(api)
    api:record(effects.BORDER_FILL, {
        style = fill.ENDLESS_SALT,
    })
end

-- Source descriptions call granite statues ruined idols throughout the
-- Desolation; this typed record survives save and inspection.
function shared.idol(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.DESOLATION_RUINED_IDOL,
    })
end

-- Only half of temple generations permute the three corridor groups.
-- Emitting the operation here keeps the source coinflip on the builder RNG.
function shared.temple_shuffle(api)
    if api:coinflip() then
        api:emit(directives.SHUFFLE, "LMN")
    end
end

return shared
