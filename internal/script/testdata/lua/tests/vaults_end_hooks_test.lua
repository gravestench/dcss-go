-- Source end-vault hook decisions use the exported production Lua modules.
-- Fixtures provide only the bounded API behavior, not duplicate DES schemas.
local directives = require("constants.vault_directives")
local features = require("constants.vault_feature_requests")
local harness = require("tests.harness")
local items = require("constants.vault_item_requests")
local no_rune = require("policy.generation.vaults.vaults_end.vaults_end_norune")
local shops = require("policy.generation.vaults.vaults_end.vaults_end_dpeg_shops1")

local test = {}

-- Capture a hook's emitted instructions while controlling only its one-in
-- draw. Production placement still parses the same directive kinds.
local function emitted_by(method, denominator, rare)
    local emitted = {}
    local api = {}

    function api:one_in(bound)
        harness.equal(bound, denominator, "source chance denominator")

        return rare
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    method(api)

    return emitted
end

-- The no-rune cell becomes a shop one time in thirteen, otherwise a good
-- item. Both requests stay typed until the placement owner resolves them.
local function no_rune_reward()
    local shop = emitted_by(no_rune.choose_reward, 13, true)
    local item = emitted_by(no_rune.choose_reward, 13, false)

    harness.equal(shop[1].kind, directives.KFEAT, "rare shop directive")
    harness.equal(shop[1].argument, "o = " .. features.ANY_SHOP,
        "rare shop request")
    harness.equal(item[1].kind, directives.KITEM, "ordinary item directive")
    harness.equal(item[1].argument, "o = " .. items.ANY_GOOD_ITEM,
        "ordinary good-item request")
end

-- The mall's rare doorway pattern does not run the common C/D shuffle.
-- Emission order is observable by the source operation engine.
local function shop_patterns()
    local rare = emitted_by(shops.choose_shop_pattern, 4, true)
    local common = emitted_by(shops.choose_shop_pattern, 4, false)

    harness.equal(#rare, 1, "rare pattern has one substitution")
    harness.equal(rare[1].kind, directives.SUBST, "rare substitution")
    harness.equal(#common, 2, "common pattern has two operations")
    harness.equal(common[1].kind, directives.SHUFFLE, "common shuffle first")
    harness.equal(common[2].kind, directives.SUBST, "common substitution second")
end

function test.run()
    no_rune_reward()
    shop_patterns()
end

return test
