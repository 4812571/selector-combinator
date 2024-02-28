local SelectorAppearance = require("scripts.selector_appearance")

local SelectorSimulation = {}

-- [ mode ]
-- "index"
-- - sort the input signals in ascending or descending order, then output the signal at the specified index

-- "count_inputs"
-- - count the number of input signals, then output the result

-- "random_input"
-- - output a randomly selected signal from among the inputs

-- "stack_size"
-- - output the stack sizes of the input signals

-- "quality transfer"
-- - transfer the quality of an input signal to the output signal(s)

function SelectorSimulation.init()
    global.selector_combinators = {}
    global.rng = game.create_random_generator()
end

function SelectorSimulation.add_combinator(event)
    local entity = event.created_entity

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
    local selector = {
        settings = {
            mode = "index",

            index_order = "descending",
            index_constant = 0,
            index_signal = nil,

            count_signal = nil,
            
            interval = 0,

            quality_selection_signal = nil,
            quality_target_signal = nil,
        },

        input_entity = entity,
        output_entity = output_entity,

        control_behavior = control_behavior
    }

    -- restore settings from blueprint
    if event.tags and event.tags["selector-combinator"] then
        selector.settings = util.table.deepcopy(event.tags["selector-combinator"])
    end

    global.selector_combinators[entity.unit_number] = selector

    -- Update the initial appearance
    SelectorAppearance.update_combinator_appearance(selector)

    -- Get this selector into its running state
    SelectorSimulation.clear_caches_and_force_update(selector)
end

function SelectorSimulation.remove_combinator(unit_number)
    local selector = global.selector_combinators[unit_number]

    global.selector_combinators[unit_number] = nil

    if selector and selector.output_entity then
        selector.output_entity.destroy()
    end
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

function SelectorSimulation.update_combinator(selector)
    local settings = selector.settings
    local mode = settings.mode

    if mode == "random_input" and game.tick % settings.interval ~= 0 then
        return
    end

    local input_signals = selector.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)
    local cache = selector.cache

    if input_signals == nil then
        -- clear any cached state required
        if mode == "index" and #cache.old_inputs ~= 0 then
            cache.old_inputs = {}
            cache.old_output_name = nil
            cache.old_output_count = 0
        elseif mode == "count_inputs" then
            cache.input_count = 0
        elseif mode == "random_input" then
            cache.old_output_name = nil
            cache.old_output_count = 0
        elseif mode == "stack_size" and #cache.old_inputs ~= 0 then
            cache.old_inputs = {}
        end

        selector.control_behavior.parameters = nil
        return
    end

    if mode == "index" then
        local old_inputs = cache.old_inputs
        if #input_signals == #old_inputs then
            local new_sig
            local old_sig
            local inputs_match = true

            for i=1, #input_signals do
                new_sig = input_signals[i]
                old_sig = old_inputs[i]
                if new_sig.count ~= old_sig.count or new_sig.signal.name ~= old_sig.signal.name then
                    -- correct mismatch, flag mismatch, and continue comparing
                    old_inputs[i] = new_sig
                    inputs_match = false
                end
            end

            if inputs_match then return end
        else
            -- the input count mismatches, update the cache
            cache.old_inputs = input_signals
        end

        local index_signal = settings.index_signal
        local signal

        if not index_signal and settings.index_constant == 0 then
            -- optimize for the common case of searching for min or max
            signal = input_signals[1]
            local count = signal.count
            if settings.index_order == "ascending" then
                for _, v in pairs(input_signals) do
                    if v.count < count then
                        signal = v
                        count = v.count
                    end
                end
            else
                for _, v in pairs(input_signals) do
                    if v.count > count then
                        signal = v
                        count = v.count
                    end
                end
            end
        else
            local index = 0

            if index_signal then
                local red_input_network = selector.input_entity.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
                local green_input_network = selector.input_entity.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)

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
                for i, v in ipairs(input_signals) do
                    if v.signal.name == index_signal.name then
                        table.remove(input_signals, i)
                        break
                    end
                end
            else
                index = settings.index_constant or 0
            end

            local lua_index = index + 1

            -- If the input signal is out of bounds, write nothing to the output constant combinator.
            if lua_index < 1 or lua_index > #input_signals then
                selector.control_behavior.parameters = nil

                return
            end

            local sorts = {
                ["ascending"] = function(a, b) return a.count < b.count end,
                ["descending"] = function(a, b) return a.count > b.count end,
            }

            table.sort(input_signals, sorts[settings.index_order])

            signal = input_signals[lua_index]
        end

        -- Determine if we actually need to update our output
        if cache.old_output_count ~= signal.count or cache.old_output_name ~= signal.signal.name then
            cache.old_output_name = signal.signal.name
            cache.old_output_count = signal.count
            selector.control_behavior.parameters = {{
                signal = signal.signal,
                count = signal.count,
                index = 1
            }}
        end

    elseif mode == "random_input" then
        local n_input_signals = #input_signals
        local signal

        if n_input_signals > 1 then
            signal = input_signals[global.rng(n_input_signals)]
        else
           signal = input_signals[1]
        end

        -- Determine if we actually need to update our output
        if cache.old_output_count ~= signal.count or cache.old_output_name ~= signal.signal.name then
            cache.old_output_name = signal.signal.name
            cache.old_output_count = signal.count
            selector.control_behavior.parameters = {{
                signal = signal.signal,
                count = signal.count,
                index = 1
            }}
        end

    elseif mode == "count_inputs" then
        -- if our number of inputs has changed, and we have a configured signal, update only the count in our cache, then output
        if #input_signals ~= cache.input_count and settings.count_signal then
            cache.input_count = #input_signals
            cache.output[1].count = cache.input_count
            selector.control_behavior.parameters = cache.output
        end

    elseif mode == "stack_size" then
        local inputs_match = true
    
        if #input_signals < #cache.old_inputs then
            cache.old_inputs = {}
            inputs_match = false
        end

        local old_inputs = cache.old_inputs
        for i=1, #input_signals do
            local name = input_signals[i].signal.name
            if name ~= old_inputs[i] then
                -- correct mismatch, flag mismatch, and continue comparing
                old_inputs[i] = name
                inputs_match = false
            end
        end

        if inputs_match then return end

        local parameters = {}
        local i = 1
        for _, signal in pairs(input_signals) do
            local item_prototype = game.item_prototypes[signal.signal.name]
            if item_prototype then
                parameters[i] = {
                    signal = signal.signal,
                    count = item_prototype.stack_size,
                    index = i
                }
                i = i + 1
            end
        end

        selector.control_behavior.parameters = parameters

    -- Quality signals, as defined in janky quality, end with a prefix '-quality-N', where N is a number from 2 to 5.
    elseif mode == "quality_transfer" then
        local quality_selection_signal = settings.quality_selection_signal

        if not quality_selection_signal then
            selector.control_behavior.parameters = nil
            return
        end

        local quality_target_signal = settings.quality_target_signal

        if not quality_target_signal then
            selector.control_behavior.parameters = nil
            return
        end

        local selection_name_stripped = without_quality_suffix(quality_selection_signal.name)
        local target_name_stripped = without_quality_suffix(quality_target_signal.name)

        local red_network = selector.input_entity.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
        local green_network = selector.input_entity.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)

        local selection_suffix = first_suffix_of(red_network, green_network, selection_name_stripped, quality_selection_signal.type)

        if not selection_suffix then
            selector.control_behavior.parameters = nil
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

            selector.control_behavior.parameters = parameters
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
                selector.control_behavior.parameters = nil
                return
            else
                local signal = {
                    name = target_name_stripped .. selection_suffix,
                    type = quality_target_signal.type,
                }

                selector.control_behavior.parameters = {
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

-- Reset the caches of a selector and force an update.
-- Trigger this whenever we migrate, change anything in the Selector GUI, or paste settings.
-- By doing this work only when settings change, we minimize the work required in on_tick.
function SelectorSimulation.clear_caches_and_force_update(selector)
    -- 1. reset cache and output
    selector.cache = {}
    selector.control_behavior.parameters = nil

    -- 2. Detect the mode and create just the caches we need
    if selector.settings.mode == "index" then
        selector.cache.old_inputs = {}

    elseif selector.settings.mode == "count_inputs" then
        selector.cache.input_count = 0

        if selector.settings.count_signal then
            selector.cache.output = {{
                signal = selector.settings.count_signal,
                -- Don't set .count; it will be written before we ever output it.
                index = 1
            }}
        end

    elseif selector.settings.mode == "random_input" then
        local placeholder = 0

    elseif selector.settings.mode == "stack_size" then
        selector.cache.old_inputs = {}

    elseif selector.settings.mode == "quality_transfer" then
        local placeholder = 0

    end

    -- 3. update this combinator
    SelectorSimulation.update_combinator(selector)
end

function SelectorSimulation.update()
    for _, selector in pairs(global.selector_combinators) do
        SelectorSimulation.update_combinator(selector)
    end
end

return SelectorSimulation