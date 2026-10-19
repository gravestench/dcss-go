local selection = {}

-- Scroll effects prepare their target selection before the read action consumes the item.
-- Example: a scroll with several eligible targets opens a selection instead of choosing the first item.
-- Known cancellation returns Okay, while empty and unknown choices follow source read semantics.
function selection.prepare(request, kind, title, no_choices, options)
    if request.cancelled then
        if request.known then
            return {
                message = "Okay.",
            }
        end

        return nil
    end

    if request.target_id == "" then
        if #options == 0 then
            if request.known then
                return {
                    message = no_choices,
                }
            end

            request.cancelled = true

            return nil
        end

        return {
            selection = {
                kind = kind,
                title = title,
                options = options,
            },
        }
    end

    for _, option in ipairs(options) do
        if option.id == request.target_id then
            return nil
        end
    end

    return {
        message = "That choice is no longer available.",
    }
end

return selection
