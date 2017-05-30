Orchestrator::Testing.mock_device 'Denon::Bluray::Dn500bd' do
    should_send("@0?VN\r")
    responds("ack+@0VN12.34.56Some Model")
    expect(status[:model_version]).to eq('12.34.56')
    expect(status[:model_name]).to eq('Some Model')

    wait(50) # delay between sends

    should_send("@0?CD\r")
    responds("ack+@0CDCI")
    expect(status[:tray_status]).to eq('disc ready')
    expect(status[:disc_ready]).to be(true)
    expect(status[:ejected]).to be(false)
    expect(status[:loading]).to be(false)

    wait(50) # delay between sends

    should_send("@0?ST\r")
    responds("ack+@0STPL")
    expect(status[:play_status]).to eq('playing')
    expect(status[:playing]).to be(true)
    expect(status[:paused]).to be(false)
end

