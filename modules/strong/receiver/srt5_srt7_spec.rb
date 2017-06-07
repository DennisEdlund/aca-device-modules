Orchestrator::Testing.mock_device 'Strong::Receiver::Srt5Srt7' do
    ack = [0xA5, 0x04, 0x00, 0xCF, 0x49, 0x7F, 0xD5]

    exec(:power, true)
        .should_send([
            0xA5, 0x07, 0x00, 0x30, 0x08,
            0x7F, 0x02, 0, 0, 247
        ])
        .responds(ack)

    wait_tick

    expect(status[:power]).to be(true)
end
