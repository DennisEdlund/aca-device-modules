load File.expand_path('./sx_ssh.rb',        File.dirname(__FILE__))
load File.expand_path('./sx_series_common.rb', File.dirname(__FILE__))


class Cisco::TelePresence::SxSeriesSsh < Cisco::TelePresence::SxSsh
    include Cisco::TelePresence::SxSeriesCommon

    # Discovery Information
    descriptive_name 'Cisco TelePresence (secure)'
    generic_name :VidConf
end
