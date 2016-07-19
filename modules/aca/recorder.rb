require 'set'
module Aca; end

class Aca::Recorder
    include ::Orchestrator::Constants


    descriptive_name 'ACA Streaming Recorder'
    generic_name :Recorder

    # Communication settings
    keepalive true
    inactivity_timeout 1500
    implements :service


    def on_load
        on_update
    end

    def on_update
        @default_group = 
    end


    def start(group_id = nil, name = nil, mode = :fullscreen, primary = :presentation, location = nil, secondary = nil)
        params = {}
        params[:name] = name if name
        params[:group_id] = group_id if group_id
        params[:mode] = mode
        params[:primary] = primary
        post('/start', {
            query: params
        }) do |resp|
            process_response(resp)
        end
    end

    Modes = Set.new [:fullscreen, :pip, :split]
    Sources = Set.new [:presentation, :camera]
    Locations = Set.new [:top_left, :top_right, :bottom_left, :bottom_right]
    # "pip", "presentation", "camera", "bottom_right"
    def layout(mode, primary, secondary = nil, location = nil)
        params = {}
        params[:mode] = mode
        params[:primary] = primary
        params[:secondary] = secondary if secondary
        params[:location] = location if location
        post('/layout', {
            query: params
        }) do |resp|
            process_response(resp)
        end
    end

    def stop
        post('/stop') do |resp|
            process_response(resp)
        end
    end

    def cancel
        post('/cancel') do |resp|
            process_response(resp)
        end
    end

    def status
        get('/status') do |resp|
            process_response(resp)
        end
    end

    def configure(pres_cmd, cam_cmd)
        params = {}
        params[:pres_cmd] = pres_cmd
        params[:cam_cmd] = cam_cmd
        post('/configure', {
            body: params
        }) do |resp|
            process_response(resp)
        end
    end


    protected


    DECODE_OPTIONS = {
        symbolize_names: true
    }.freeze

    def process_response(resp)
        data = nil

        if resp.body && resp.body.length > 0
            data = begin
                ::JSON.parse(resp.body, DECODE_OPTIONS)
            rescue => e
                logger.print_error(e, 'failed to decode response')
                return :abort
            end
        end

        logger.debug { "Recorder responded with #{data}" }
        :success
    end
end
