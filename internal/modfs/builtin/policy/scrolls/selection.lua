local selection = {}

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
