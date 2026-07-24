require 'rails_helper'

RSpec.describe EtCcdExport::MultiplesBatchJob do
  let(:example_worker_class) do
    Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
      include EtCcdExport::MultiplesBatchJob

      def perform
        # Do nothing
      end
    end
  end

  before do
    stub_const('ExampleWorker', example_worker_class)
  end

  context 'perform' do
    it 'adds child job to todo in batch' do
      batch = EtCcdExport::Sidekiq::Batch.start reference: 'parent-reference',
                                                quantity: 100,
                                                start_ref: '100000001',
                                                export_id: 1,
                                                case_type_id: 'fakecasetypeid'
      batch.jobs do
        batch.child_job('100000001') do
          ExampleWorker.perform_later
        end
      end

      refs = batch.todo_references
      expect(refs).to eq(['100000001'])

      job_data = ActiveJob::Base.queue_adapter.enqueued_jobs.last

      expect(job_data).to include(
        'et_ccd_export_metadata' => {
          "et_ccd_export_multiple_batch_reference" => "parent-reference",
          "et_ccd_export_multiple_batch_child_reference" => "100000001"
        }
      )
    end
  end
end
