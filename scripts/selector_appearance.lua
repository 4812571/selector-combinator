local SelectorAppearance = {}

function SelectorAppearance.update_combinator_appearance(entity)
    local entry = global.selector_combinators[entity.unit_number]

    if not entry then
        return
    end

    local control_behavior = entry.input_entity.get_or_create_control_behavior()
    local parameters = control_behavior.parameters

    local mode = entry.mode

    if mode == "index" then
        if entry.index_order == "ascending" then
            parameters.operation = "*"
        else
            parameters.operation = "/"
        end
    end

    if mode == "count" then
        parameters.operation = "+"
    end

    if mode == "stack_size" then
        parameters.operation = "-"
    end

    if mode == "quality_transfer" then
        parameters.operation = "%"
    end

    control_behavior.parameters = parameters
end

return SelectorAppearance