module Amx; end
module Amx::Svsi; end


class Amx::Svsi::VirtualVideowall
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder


    descriptive_name 'AMX SVSI Virtual Videowall'
    generic_name :Videowall
    implements :logic

description <<-DESC
This module may be used to define, and recall, videowall windowing layouts for SVSI decoders in a system. Layouts should be defined under the `videowall_presets` key and each may contain an arbitary number of windows.

Each window definition can be formed of any available decoders, positioned within a 2D array. A scaling mode (either `auto`, `fit`, or `stretch`) may also optionally be defined.

```
{
    "videowall_presets": {
        "dual": [
            {
                "scale": "auto",
                "decoders": [
                    [1, 2],
                    [3, 4]
                ]
            },
            {
                "scale": "auto",
                "decoders": [
                    [5, 6],
                    [7, 8]
                ]
            }
        ],
        "centered": [
            {
                "scale": "auto",
                "decoders": [
                    [2, 5],
                    [4, 7]
                ]
            },
            {
                "decoders": 1
            },
            {
                "decoders": 3
            },
            {
                "decoders": 6
            },
            {
                "decoders": 8
            }
        ]
    }
}
```
DESC


    def on_load
        on_update
    end

    def on_update
        @presets = settings(:videowall_presets)
    end


    def preset(id)
        windows = @presets[id.to_s]

        if windows.nil?
            logger.error { "videowall preset #{id} has not been defined" }
            return
        end

        decoders = system.all(:Decoder)

        [*windows].each do |window|
            scaling = window[:scale] || 'auto'
            layout = window[:decoders]

            # convert to a 2d array if it's not (i.e. standalone)
            layout = Array layout
            layout.map! { |x| Array x }

            width = layout.map(&:length).max
            height = layout.length

            layout.each_with_index do |row, y|
                row.each_with_index do |decoder, x|
                    decoder = decoders[decoder - 1]
                    unless decoder.nil?
                        decoder.videowall width, height, x, y, scaling
                    else
                        logger.warn "could not find decoder \"#{decoder}\""
                    end
                end
            end
        end

        self[:preset] = id.to_s
    end

    # Get a list of decoders grouped under a specific window in the current
    # layout
    def decoders(window_num)
        current_preset = self[:preset]
        window = @presets[current_preset][window_num]

        unless window.nil?
            [*window[:decoders]].flatten
        else
            log.warning \
                "window #{window_num} not available in #{current_preset}"
            []
        end
    end

end
