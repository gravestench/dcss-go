-- Theory of operation: Zin takes one tenth of newly collected gold, carrying
-- fractional tenths in the saved wallet. A pile first seen before conversion
-- still pays money but grants no piety. Acquirement pays normally but its
-- piety uses source stepdown, preventing one scroll from filling six stars.
-- Joining taxes carried gold that was not covered by earlier donations.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local branches = require("ids.branches")
local gods = require("constants.gods")
local classes = require("ids.object_classes")
local limits = require("constants.piety")
local piety = require("policy.religion.piety")
local states = require("constants.zin_tithe_state")
local rules = require("constants.zin_tithe_rules")
local wallet_limits = require("constants.wallet_limits")

local zin = {}

-- A source gold stack is marked when first seen, not when generated. This
-- lets a player find a pile, change gods, and still pay a late tithe on it.
-- Repeated visibility never changes the original sighting decision.
function zin.mark_seen(ctx, player, entity)
    local item = ctx:get(entity, component.ITEM)

    if not item or
        catalog.get(categories.ITEMS, item.kind_id).class ~= classes.OBJ_GOLD then
        return
    end

    local metadata = ctx:get(entity, component.GOLD_TITHE) or {}

    if metadata.state and metadata.state ~= states.DEFAULT then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    metadata.state = worship and worship.god_id == gods.ZIN and
        states.FULL_TITHE or states.NO_PIETY

    if ctx:has(entity, component.GOLD_TITHE) then
        ctx:set(entity, component.GOLD_TITHE, metadata)
    else
        ctx:add(entity, component.GOLD_TITHE, metadata)
    end
end

-- C++ stepdown_value(whole, 10, 10, 50, 50) applies only to gold from an
-- acquirement scroll or the one-time carried-gold conversion. The source
-- rounds the logarithmic result downward and caps it at fifty.
local function acquired_piety(whole)
    if whole <= 10 then
        return whole
    end

    local stepped = math.floor(rules.DIVISOR *
        math.log(1 + whole / rules.DIVISOR) / math.log(2))

    return math.min(rules.ACQUIREMENT_PIETY_CAP, stepped)
end

-- Resolve the current floor from the branch catalog rather than storing a
-- duplicate absolute depth on the player. A context without a position is
-- the D:1 rule fixture; live players always have a level position.
local function absolute_depth(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return 0
    end

    local branch_id = ctx:level_branch(position.level_id)
    local depth = ctx:level_depth(position.level_id)

    if not branch_id or not depth then
        error("Zin tithe requires the player's branch and depth")
    end

    local branch = catalog.get(categories.BRANCHES, branch_id)

    return branch.absolute_depth + depth - 1
end

-- Quote the full transaction without changing any ECS state. The wallet
-- owner can reject overflow before piety, gold, or the floor item changes.
local function quote(ctx, player, amount, metadata, converting, wallet)
    local state = metadata.state or states.DEFAULT

    if state ~= states.DEFAULT and state ~= states.NO_PIETY and
        state ~= states.FULL_TITHE and state ~= states.NO_TITHE then
        error("invalid Zin gold tithe state " .. tostring(state))
    end

    if state == states.NO_TITHE then
        return {
            taken = 0,
            remainder = wallet.tithe_base,
            numerator = 0,
            denominator = 1,
            late = false,
        }
    end

    if amount > wallet_limits.MAX_EXACT - wallet.tithe_base then
        error("Zin tithe amount would overflow")
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local due = amount + wallet.tithe_base
    local whole = math.floor(due / rules.DIVISOR)
    local cap = math.floor(((worship.penance[gods.ZIN] or 0) +
        limits.MAX - worship.piety) * rules.CAP_NUMERATOR /
        rules.CAP_DENOMINATOR)
    local taken = math.min(whole, math.max(0, cap))
    local result = {
        taken = taken,
        remainder = due % rules.DIVISOR,
        numerator = 0,
        denominator = 1,
        late = state == states.NO_PIETY,
    }

    if taken == 0 or result.late then
        return result
    end

    if metadata.acquired or converting then
        result.numerator = acquired_piety(taken) * rules.PIETY_NUMERATOR
        result.denominator = rules.PIETY_DENOMINATOR

        return result
    end

    local position = ctx:get(player, component.POSITION)
    local orc = position and
        ctx:level_branch(position.level_id) == branches.BRANCH_ORC
    local orc_factor = orc and 2 or 1

    result.numerator = taken * rules.ORDINARY_PIETY_MULTIPLIER *
        rules.PIETY_NUMERATOR
    result.denominator = rules.PIETY_DENOMINATOR * orc_factor *
        (rules.DEPTH_PIETY_BASE + absolute_depth(ctx, player))

    return result
end

-- The message and piety are consequences of the same completed debit. A
-- late pile announces Zin's refusal even though its cash tithe was paid.
local function reward(ctx, player, result)
    if result.taken == 0 then
        return
    end

    ctx:emit(channels.RELIGION,
        "You pay a tithe of " .. result.taken .. " gold.")

    if result.late then
        ctx:emit(channels.RELIGION, "Zin ignores your late donation.")

        return
    end

    piety.gain(ctx, player, result.numerator, result.denominator, false)
end

-- Credit a floor stack after the generic wallet owner has checked its item
-- identity and location. Zin owns only this god's tax and piety arithmetic;
-- the caller still destroys the floor item after a successful transaction.
function zin.gold_pickup(ctx, player, entity, amount)
    local wallet = ctx:get(player, component.WALLET)
    local metadata = ctx:get(entity, component.GOLD_TITHE) or {}
    local result = quote(ctx, player, amount, metadata, false, wallet)
    local credited = amount - result.taken

    if wallet.gold > wallet_limits.MAX_EXACT - credited or
        wallet.donations > wallet_limits.MAX_EXACT - result.taken then
        error("Zin gold pickup would overflow the wallet")
    end

    wallet.gold = wallet.gold + credited
    wallet.donations = wallet.donations + result.taken
    wallet.tithe_base = result.remainder
    ctx:set(player, component.WALLET, wallet)
    reward(ctx, player, result)

    return credited
end

-- Only the portion of carried cash not already covered by past donations
-- pays upon conversion. It uses acquirement's capped piety formula, as the
-- source does when it constructs a temporary gold item for this purpose.
function zin.join(ctx, player)
    local wallet = ctx:get(player, component.WALLET)
    local exempt = math.min(wallet.gold,
        wallet.donations * rules.ENTRY_EXEMPT_PER_DONATION)
    local untithed = wallet.gold - exempt

    if untithed <= 0 then
        return
    end

    local result = quote(ctx, player, untithed, {
        acquired = true,
    }, true, wallet)

    if wallet.donations > wallet_limits.MAX_EXACT - result.taken then
        error("Zin entry tithe would overflow donations")
    end

    wallet.gold = wallet.gold - result.taken
    wallet.donations = wallet.donations + result.taken
    wallet.tithe_base = result.remainder
    ctx:set(player, component.WALLET, wallet)
    reward(ctx, player, result)
end

return zin
