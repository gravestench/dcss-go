-- DES chance and weight clauses can contain comma-separated depth groups.
local specifiers = {}

-- Split only outside parentheses so a group such as (D:1, Lair) stays one
-- clause. Reject malformed groups before a selector can misread their odds.
function specifiers.split(argument, site)
    local clauses = {}
    local start = 1
    local nesting = 0

    for index = 1, #argument do
        local char = argument:sub(index, index)

        if char == "(" then
            nesting = nesting + 1
        elseif char == ")" then
            nesting = nesting - 1

            if nesting < 0 then
                error(string.format("%s:%d: vault %s: unmatched ')'",
                    site.path, site.line, site.id))
            end
        elseif char == "," and nesting == 0 then
            clauses[#clauses + 1] = argument:sub(start, index - 1)
            start = index + 1
        end
    end

    if nesting ~= 0 then
        error(string.format("%s:%d: vault %s: unmatched '('",
            site.path, site.line, site.id))
    end

    clauses[#clauses + 1] = argument:sub(start)

    return clauses
end

return specifiers
