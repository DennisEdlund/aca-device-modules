require 'slack-ruby-client'
require 'slack/real_time/concurrency/libuv'

class Aca::Slack
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder
    include ::Orchestrator::Security


    descriptive_name 'Slack Connector'
    generic_name :Slack
    implements :logic

    def on_load
        create_websocket

        on_update
    end

    def on_update
        self[:building] = setting(:building) || :barangaroo
        self[:channel] = setting(:channel) || :concierge
    end

    # Message coming in from Slack API
    def on_message(data)
        logger.debug "------------------ Received message! ------------------"
        logger.debug data.inspect
        logger.debug "-------------------------------------------------------"
        # This should always be set as all messages from the slack client should be replies
        if data.thread_ts
            user_id = get_user_id(data.thread_ts)
            self["last_message_#{user_id}"] = data
        end
    end

    # Message from the frontend
    def send_message(message_text)
        user = current_user
        thread_id = get_thread_id(user)

        if thread_id
            # Post to the slack channel using the thread ID
            message = @client.web_client.chat_postMessage channel: setting(:channel), text: message_text, username: "#{current_user.name} (#{current_user.email})", thread_ts: thread_id

        else
            message = @client.web_client.chat_postMessage channel: setting(:channel), text: message_text, username: "#{current_user.name} (#{current_user.email})"            
            # Store thread id
            thread_id = message['message']['ts']
            User.bucket.set("slack-thread-#{user.id}-#{setting(:building)}", thread_id)
            User.bucket.set("slack-user-#{thread_id}", user.id)
        end
    end

    def get_historic_messages
        user = current_user
        thread_id = get_thread_id(user)

        if thread_id
            # Get the messages
            slack_api = UV::HttpEndpoint.new("https://slack.com")
            req = {
                token: @client.token,
                channel: setting(:channel),
                thread_ts: thread_id
            }
            response = slack_api.post(path: 'https://slack.com/api/channels.replies', body: req).value
            
            messages = JSON.parse(response.body)['messages']
            
            {
                thread_id: thread_id,
                messages: messages
            }
        else
            {
                thread_id: nil,
                messages: []
            }
        end
    end


    protected

    def get_thread_id(user)
        User.bucket.get("slack-thread-#{user.id}-#{setting(:building)}", quiet: true)
    end

    def get_user_id(thread_id)
        User.bucket.get("slack-user-#{thread_id}", quiet: true)
    end

    # Create a realtime WS connection to the Slack servers
    def create_websocket

        ::Slack.configure do |config|
            config.token = setting(:slack_api_token)
            config.logger = Logger.new(STDOUT)
            config.logger.level = Logger::INFO
            fail 'Missing slack api token setting!' unless config.token
        end
	::Slack::RealTime.configure do |config|
	    config.concurrency = Slack::RealTime::Concurrency::Libuv
	end

        @client = ::Slack::RealTime::Client.new

        logger.debug "Created client!!"

        @client.on :message do |data|
            logger.debug "Got message!"
	    begin
            #@client.typing channel: data.channel
            on_message(data)
	    rescue Exception => e
	    logger.debug e.message
	    logger.debug e.backtrace
	    end

        end
	@client.start!

    end

end
