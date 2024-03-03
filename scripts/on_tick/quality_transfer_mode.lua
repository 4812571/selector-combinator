local QualityTransferMode = {}

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
end

function QualityTransferMode:on_tick()
    local settings = self.settings
    local mode = settings.mode

    local input_signals = self.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)
    local cache = self.cache

    if input_signals == nil then
        if not cache.previous_input_was_nil then
            self.control_behavior.parameters = nil
            cache.previous_input_was_nil = true
        end
        return
    end

    cache.previous_input_was_nil = false
    
    local quality_selection_signal = settings.quality_selection_signal

    if not quality_selection_signal then
        self.control_behavior.parameters = nil
        return
    end

    local quality_target_signal = settings.quality_target_signal

    if not quality_target_signal then
        self.control_behavior.parameters = nil
        return
    end

    local selection_name_stripped = without_quality_suffix(quality_selection_signal.name)
    local target_name_stripped = without_quality_suffix(quality_target_signal.name)

    local red_network = self.input_entity.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
    local green_network = self.input_entity.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)

    local selection_suffix = first_suffix_of(red_network, green_network, selection_name_stripped, quality_selection_signal.type)

    if not selection_suffix then
        self.control_behavior.parameters = nil
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

        self.control_behavior.parameters = parameters
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
            self.control_behavior.parameters = nil
        else
            local signal = {
                name = target_name_stripped .. selection_suffix,
                type = quality_target_signal.type,
            }

            self.control_behavior.parameters = {{
                    signal = signal,
                    count = total_of_input,
                    index = 1
                }}
        end
    end
end

return QualityTransferMode
