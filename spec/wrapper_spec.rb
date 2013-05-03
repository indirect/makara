require 'spec_helper'

describe 'Makara Connection Wrappers' do

  before { connect!(config) }

  let(:config){ single_slave_config }
  let(:one){ adapter.slave(1) }

  describe '#blacklist!' do

    it 'should schedule the blacklist properly' do
      Delorean.time_travel_to Time.now do
        adapter.master.blacklist!
        adapter.master.instance_variable_get('@blacklisted_until').should be_within(1).of(Time.now)
      end

      Delorean.time_travel_to Time.now do
        one.blacklist!
        one.instance_variable_get('@blacklisted_until').should be_within(1).of(1.minute.from_now)
      end
    end

  end

  describe '#blacklisted?' do

    it 'should return the correct value' do
      one.should_not be_blacklisted
      one.blacklist!
      one.should be_blacklisted
    end

    it 'should reconnect if it\'s served it\'s time' do
      one.connection.should_receive(:reconnect!).once
      one.blacklist!
      Delorean.time_travel_to 70.seconds.from_now do
        one.should_not be_blacklisted
      end
    end

    it 'should extend the blacklisting if the reconnection fails' do
      one.connection.should_receive(:reconnect!).and_raise('This is a reconnect error!')
      one.blacklist!

      Delorean.time_travel_to 70.seconds.from_now do
        one.should be_blacklisted
        one.instance_variable_get('@blacklisted_until').should be_within(1).of(1.minute.from_now)
      end
    end

  end
end