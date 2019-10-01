shared_context 'with mock api event worker' do
  let(:mock_job_wrapper) { double('MockJobWrapper', drain: nil) }
  before do
    stub_const('ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper', mock_job_wrapper)
  end
end