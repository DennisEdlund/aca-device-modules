load File.expand_path('./sx_ssh.rb', File.dirname(__FILE__))
load File.expand_path('./sx_camera_common.rb', File.dirname(__FILE__))


class Cisco::TelePresence::SxCameraSsh < Cisco::TelePresence::SxSsh
    include Cisco::TelePresence::SxCameraCommon

    descriptive_name 'Cisco TelePresence Camera (secure)'
    generic_name :Camera
end
