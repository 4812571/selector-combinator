local SelectorAppearance = require("scripts.selector_appearance")

local SelectorSimulation = {}

-- [ mode ]
-- "index"
-- - sort the input signals in ascending or descending order, then output the signal at the specified index

-- "count_inputs"
-- - count the number of input signals, then output the result

-- "stack_size"
-- - output the stack sizes of the input signals

-- "quality transfer"
-- - transfer the quality of an input signal to the output signal(s)

function SelectorSimulation.init()
    global.selector_combinators = {}
end

function SelectorSimulation.add_combinator(entity)
    -- Register the entity for the destruction event.
    script.register_on_entity_destroyed(entity)

    -- Create the invisible output constant combinator
    local output_entity = entity.surface.create_entity {
        name = "selector-out-combinator",
        position = entity.position,
        force = entity.force,
        fast_replace = false,
        raise_built = false,
        create_build_effect_smoke = false,
    }

    -- Create a control behavior so that the output combinator can have signals set on it.
    local control_behavior = output_entity.get_or_create_control_behavior()

    -- Connect the output entity to the outputs of the selector combinator, so that the outputs are connected 
    -- parallel with the actual outputs of the selector combinator.
    entity.connect_neighbour {
        wire = defines.wire_type.red,
        target_entity = output_entity,
        source_circuit_id = defines.circuit_connector_id.combinator_output,
    }

    entity.connect_neighbour {
        wire = defines.wire_type.green,
        target_entity = output_entity,
        source_circuit_id = defines.circuit_connector_id.combinator_output,
    }

    -- Create and store the global data entry
    local selector_data = {
        mode = "index",

        index_order = "ascending",
        index_constant = 0,
        index_signal = nil,

        count_signal = nil,

        quality_selection_signal = nil,
        quality_target_signal = nil,

        input_entity = entity,
        output_entity = output_entity,

        control_behavior = control_behavior,
    }

    global.selector_combinators[entity.unit_number] = selector_data

    -- Update the initial appearance
    SelectorAppearance.update_combinator_appearance(entity)
end

function SelectorSimulation.remove_combinator(unit_number)
    global.selector_combinators[unit_number] = nil
end

local function without_quality_suffix(name)
    local end_of_name = string.find(name, "-quality-")

    if end_of_name then
        return string.sub(name, 1, end_of_name - 1)
    else
        return name
    end
end

local suffixes = {
    [1] = "",
    [2] = "-quality-2",
    [3] = "-quality-3",
    [4] = "-quality-4",
    [5] = "-quality-5",
}

local function first_suffix_of(red_network, green_network, stripped_name, signal_type)
    for _, suffix in ipairs(suffixes) do
        local search_signal = {
            name = stripped_name .. suffix,
            type = signal_type,
        }

        local red_signal = red_network and red_network.get_signal(search_signal) or 0
        local green_signal = green_network and green_network.get_signal(search_signal) or 0

        if red_signal + green_signal ~= 0 then
            return suffix
        end
    end

    return nil
end

function SelectorSimulation.update_combinator(entry)
    local mode = entry.mode
    local input_signals = entry.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)

    local control_behavior = entry.control_behavior

    if input_signals == nil then
        control_behavior.parameters = nil

        return
    end


    if mode == "index" then
        local index_signal = entry.index_signal

        local index = 0

        if index_signal then
            local red_input_network = entry.input_entity.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
            local green_input_network = entry.input_entity.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)

            local red_signal = 0

            if red_input_network then
                red_signal = red_input_network.get_signal(index_signal)
            end

            local green_signal = 0

            if green_input_network then
                green_signal = green_input_network.get_signal(index_signal)
            end

            index = red_signal + green_signal

            -- Remove the index signal from the input signals
            for i, signal in ipairs(input_signals) do
                if signal.signal.name == index_signal.name then
                    table.remove(input_signals, i)
                    break
                end
            end
        else
            index = entry.index_constant
        end

        local lua_index = index + 1

        -- If the input signal is out of bounds, write nothing to the output constant combinator.
        if lua_index < 1 or lua_index > #input_signals then
            control_behavior.parameters = nil

            return
        end

        local sorts = {
            ["ascending"] = function(a, b) return a.count < b.count end,
            ["descending"] = function(a, b) return a.count > b.count end,
        }

        table.sort(input_signals, sorts[entry.index_order])

        local signal = input_signals[lua_index]

        -- Write the signal to the output constant combinator.
        control_behavior.parameters = {
            {
                signal = signal.signal,
                count = signal.count,
                index = 1,
            },
        }

        return
    end

    if mode == "count_inputs" then
        local count_signal = entry.count_signal

        if not count_signal then
            control_behavior.parameters = nil

            return
        end

        local signal_count = #input_signals

        control_behavior.parameters = {
            {
                signal = count_signal,
                count = signal_count,
                index = 1,
            },
        }

        return
    end

    if mode == "stack_size" then
        local parameters = {}

        for _, signal in pairs(input_signals) do
            local item_prototype = game.item_prototypes[signal.signal.name]

            if item_prototype then
                local stack_size = item_prototype.stack_size

                table.insert(parameters, {
                    signal = signal.signal,
                    count = stack_size * signal.count,
                    index = 1,
                })
            end
        end

        control_behavior.parameters = parameters

        return
    end

    -- Quality signals, as defined in janky quality, end with a prefix '-quality-N', where N is a number from 2 to 5.
    if mode == "quality_transfer" then
        local quality_selection_signal = entry.quality_selection_signal

        if not quality_selection_signal then
            control_behavior.parameters = nil
            return
        end

        local quality_target_signal = entry.quality_target_signal

        if not quality_target_signal then
            control_behavior.parameters = nil
            return
        end

        local selection_name_stripped = without_quality_suffix(quality_selection_signal.name)
        local target_name_stripped = without_quality_suffix(quality_target_signal.name)

        local red_network = entry.input_entity.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
        local green_network = entry.input_entity.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)

        local selection_suffix = first_suffix_of(red_network, green_network, selection_name_stripped, quality_selection_signal.type)

        if not selection_suffix then
            control_behavior.parameters = nil
            return
        end

        -- If the target signal is 'each', we need to transfer the quality of every signal to the output.
        if target_name_stripped == "signal-each" then
            local output_values = {}
            local output_types = {}

            for _, signal in pairs(input_signals) do
                -- If the signal is the selection signal, skip it.
                local signal_name_stripped = without_quality_suffix(signal.signal.name)

                if not (signal_name_stripped == selection_name_stripped) then
                    local current_value = output_values[signal_name_stripped]

                    if not current_value then
                        output_values[signal_name_stripped] = signal.count
                        output_types[signal_name_stripped] = signal.signal.type
                    else
                        output_values[signal_name_stripped] = current_value + signal.count
                    end
                end
            end

            local parameters = {}

            local counter = 1

            for name, value in pairs(output_values) do
                local signal = {
                    name = name .. selection_suffix,
                    type = output_types[name],
                }

                table.insert(parameters, {
                    signal = signal,
                    count = value,
                    index = counter
                })

                counter = counter + 1
            end

            control_behavior.parameters = parameters
        else
            local total_of_input = 0

            for _, prefix in ipairs(suffixes) do
                local search_signal = {
                    name = target_name_stripped .. prefix,
                    type = quality_target_signal.type,
                }

                local red_signal = red_network and red_network.get_signal(search_signal) or 0
                local green_signal = green_network and green_network.get_signal(search_signal) or 0

                total_of_input = total_of_input + red_signal + green_signal
            end

            if total_of_input == 0 then
                control_behavior.parameters = nil
                return
            else
                local signal = {
                    name = target_name_stripped .. selection_suffix,
                    type = quality_target_signal.type,
                }

                control_behavior.parameters = {
                    {
                        signal = signal,
                        count = total_of_input,
                        index = 1,
                    },
                }

                return
            end
        end
    end
end

function SelectorSimulation.update()
    for _, entry in pairs(global.selector_combinators) do
        SelectorSimulation.update_combinator(entry)
    end
end

return SelectorSimulation