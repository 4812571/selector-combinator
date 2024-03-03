local RandomInputMode = {}

function RandomInputMode:on_tick()
    local settings = self.settings
    local mode = settings.mode

    if game.tick % settings.interval ~= 0 then return end

    local input_signals = self.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)
    local cache = self.cache

    if input_signals == nil then
        if not cache.previous_input_was_nil then
            cache.old_output_name = nil
            cache.old_output_count = 0

            self.control_behavior.parameters = nil
            cache.previous_input_was_nil = true
        end
        return
    end

    cache.previous_input_was_nil = false

    local n_input_signals = #input_signals
    local signal

    if n_input_signals > 1 then
        signal = input_signals[global.rng(n_input_signals)]
    else
       signal = input_signals[1]
    end

    -- Determine if we actually need to update our output
    if signal.count ~= cache.old_output_count or signal.signal.name ~= cache.old_output_name then
        cache.old_output_name = signal.signal.name
        cache.old_output_count = signal.count
        self.control_behavior.parameters = {{
            signal = signal.signal,
            count = signal.count,
            index = 1
        }}
    end
end

return RandomInputMode
