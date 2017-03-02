module TvOne; end

class TvOne::WindowStacker
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    descriptive_name 'Videowall Window Stacker Logic'
    generic_name :WindowStacker
    implements :logic

description <<-DESC
The CORIOmaster videowall processors does not provide the ability to hide
windows on signal loss. This logic module may be used to bind windows used
in a layout to displays defined within a system. When a display has no source
routed it's Z-index will be dropped to 0, revealing background content.

Use settings to define mapping between system outputs and window ID's:
```
{
    "windows": {
        "Display_1": [1, 2, 3],
        "Display_2": 7,
        "Display_3": [9, 4]
    }
}
```
DESC


    def on_load
        @subscriptions = []
        on_update
    end

    def on_update
        @subscriptions.each do |reference|
            unsubscribe(reference)
        end

        bindings = setting(:windows) || {}
        @show = setting(:show) || 15  # visible z layer
        @hide = setting(:hide) || 0   # hidden z layer

        @subscriptions = bindings.map do |display_key, window_ids|
            relayer window_ids system[display_key][:source]
            link display_key, window_ids
        end
    end


    protected


    def relayer(window, source)
        z_index = source == :none ? @hide : @show
        [*window].each do |id|
            system[:VideoWall].window id, "Zorder", z_index
        end
    end


    def link(display, window)
        system.subscribe(:System, 1, display) do |notice|
            source = notice.value[:source]
            relayer window, source
        end
    end

end
