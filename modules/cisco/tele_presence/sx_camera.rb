load File.expand_path('./sx_telnet.rb', File.dirname(__FILE__))
load File.expand_path('./sx_camera_common.rb', File.dirname(__FILE__))


class Cisco::TelePresence::SxCamera < Cisco::TelePresence::SxTelnet
    include Cisco::TelePresence::SxCameraCommon

    descriptive_name 'Cisco TelePresence Camera'
    generic_name :Camera
end
