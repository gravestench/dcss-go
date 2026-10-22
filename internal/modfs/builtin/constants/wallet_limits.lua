-- Lua numbers can represent every integer through this bound exactly.
-- Keep the wallet and religious debits on the same arithmetic limit.
local limits = {
    MAX_EXACT = 9007199254740991,
}

return limits
