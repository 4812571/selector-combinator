local IndexMode = {}

function IndexMode:on_tick()
    local settings = self.settings
    local mode = self.mode

    local input_signals = self.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)
    local cache = self.cache

    if input_signals == nil then
        if not cache.previous_input_was_nil then
            cache.old_inputs = {}
            cache.old_output_name = nil
            cache.old_output_count = 0

            self.control_behavior.parameters = nil
            cache.previous_input_was_nil = true
        end

        return
    end

    cache.previous_input_was_nil = false

    local old_inputs = cache.old_inputs
    local n_input_signals = #input_signals

    -- 1. Check to see if our inputs are unchanged.
    if n_input_signals == #old_inputs then
        local inputs_match = true

        for i=1, n_input_signals do
            local new_sig = input_signals[i]
            local old_sig = old_inputs[i]
            if new_sig.count ~= old_sig.count or new_sig.signal.name ~= old_sig.signal.name then
                -- correct mismatch, flag mismatch, and continue comparing
                old_inputs[i] = new_sig
                inputs_match = false
            end
        end

        if inputs_match then return end
    else
        -- the input count mismatches, update the cache
        cache.old_inputs = {}
        local old_inputs = cache.old_inputs
        for i=1, n_input_signals do
            old_inputs[i] = input_signals[i]
        end
    end

    local index_signal = settings.index_signal
    local index

    -- 2. Get the index. If an index signal is provided, find and remove it from among the inputs.
    if index_signal then
        index = 1
        local name = index_signal.name
        for i, v in ipairs(input_signals) do
            if v.signal.name == name then
                index = v.count + 1
                table.remove(input_signals, i)
                n_input_signals = n_input_signals - 1
                break
            end
        end
    else
        index = settings.index_constant + 1
    end

    local signal

    -- 3. Select the n-th signal, optimizing for the common cases of searching for min or max.
    if index == 1 then
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
    elseif index < 1 or index > n_input_signals then
        -- The input signal is out of bounds, clear the cache and the output
        cache.old_output_name = nil
        cache.old_output_count = 0
        self.control_behavior.parameters = nil
        return
    else -- The index is valid and greater than 1, we must sort
        table.sort(input_signals, cache.sort)
        signal = input_signals[index]
    end

    -- 4. Update our output if we need to.
    if cache.old_output_count ~= signal.count or cache.old_output_name ~= signal.signal.name then
        cache.old_output_name = signal.signal.name
        cache.old_output_count = signal.count
        self.control_behavior.parameters = {{
            signal = signal.signal,
            count = signal.count,
            index = 1
        }}
    end
end

return IndexMode
