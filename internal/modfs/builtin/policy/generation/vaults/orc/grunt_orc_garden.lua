-- Theory of operation: the mapless gardens ending places four copies of
-- this source helper. Each placement receives its own theme, boss role,
-- and shop through the controller's local settings. No Lua global carries
-- values between maps, and the chosen entities and shop become map records.
local directives = require("constants.vault_directives")
local settings = require("constants.orc_gardens")

local garden = {}

-- Fill the source monster slots and substitute the center according to
-- the one-in-eight giant theme and this helper's assigned boss role.
local function configure(api)
    local giant = api:setting(settings.GIANT)
    local boss = api:setting(settings.BOSS)

    if giant then
        api:emit(directives.MONS, boss and "stone giant" or "ettin")
        api:emit(directives.MONS, "cyclops")
        api:emit(directives.MONS, "nothing")
        api:emit(directives.NSUBST, "0 : 1:1 / 2:2 / *:.")

        return
    end

    if boss then
        api:emit(directives.MONS, "orc warlord")
    end

    api:emit(directives.MONS,
        "orc knight / orc sorcerer w:5 / orc high priest w:5")

    if not boss then
        api:emit(directives.MONS, "nothing")
    end

    api:emit(directives.MONS,
        "orc warrior / orc sorcerer w:1 / orc high priest w:1 / " ..
        "ogre w:1 / troll w:1 / warg w:1")
    api:emit(directives.NSUBST, "0 : 1:1 / *:2")
end

-- A direct map validation has no parent controller, so any shop is a
-- source-valid fallback. A child placement uses its assigned source store.
local function choose_shop(api)
    local shop = api:setting(settings.SHOP)

    if api:validating() or not shop then
        shop = "any shop"
    end

    api:emit(directives.KFEAT, "A = " .. shop)
end

garden.configure = configure
garden.choose_shop = choose_shop

return garden
