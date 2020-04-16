require 'rails_helper'
RSpec.describe EthosReferenceGeneratorService do
  subject(:service) { described_class }

  it 'increments by 1 given a low starting point' do
    expect(service.call('1200001/2019')).to eql '1200002/2019'
  end

  it 'increments by 1 given a high starting point' do
    expect(service.call('1299998/2019')).to eql '1299999/2019'
  end

  it 'wraps around correctly' do
    expect(service.call('1299999/2019')).to eql '1200001/0019'
  end

  it 'raises an exception if wrapped around twice' do
    expect { service.call('1299999/0019') }.to raise_exception RuntimeError, 'All reference numbers used up'
  end
end