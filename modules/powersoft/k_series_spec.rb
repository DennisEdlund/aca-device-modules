Orchestrator::Testing.mock_device 'Powersoft::KSeries' do
    exec(:power, true)
        .should_send([0x02, 54, 53, 0x70, 0x31, 64, 0x03])
        .responds([0x02, 54, 53, 0x06, 0x43, 0x03])

    wait_tick
    expect(status[:power]).to be(true)
end
