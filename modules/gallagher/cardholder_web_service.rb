require 'httpi/adapter/libuv'
require 'savon'
HTTPI.adapter = :libuv

module Gallagher; end

=begin

    For a call to be made, a certificate is deployed from a deployment utility and installed on the remote server
    WSDL at https://host:8082/Cardholder/?WSDL

=end

class Gallagher::CardholderWebService
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    # Discovery Information
    implements :service
    descriptive_name 'Gallagher Cardholder Web Service'
    generic_name :Security


    def on_load
        self[:wsdl_loaded] = false
        on_update
    end

    def on_unload
        destroy_session_token
    end

    def on_update
        @client_version = setting(:client_version)
        @username       = setting(:username)
        @password       = setting(:password)
        @client_cert    = setting(:client_certificate)

        connect
    end

    def connect
        # Prevent cascading async loop
        return if @connecting
        @connecting = true

        # Configure service
        request_wsdl
        obtain_session_token
        set_connected_state(true)
    rescue => e
        @session = nil
        logger.print_error(e, 'connecting to service')
        set_connected_state(false)
        schedule.in('30s') { connect }
    ensure
        @connecting = false
    end


    protected


    def request_wsdl
        @client = Savon.client({
            wsdl: remote_address,
            ssl_cert_file: @client_cert,
            convert_request_keys_to: :lower_camelcase
        })
        self[:operations] = @client.operations
        self[:wsdl_loaded] = true
    end

    def obtain_session_token
        @session = @client.call(:connect, message: {
            client_version: @client_version,
            username: @username,
            password: @password
        }).body[:connect_response]
    end

    def destroy_session_token
        return if @session.nil?

        resp = @client.call(:disconnect, message: {
            session_token: @session
        })
        logger.debug { "destroy response:\n#{resp.body[:disconnect_response]}" }
        @session = nil
    end
end

