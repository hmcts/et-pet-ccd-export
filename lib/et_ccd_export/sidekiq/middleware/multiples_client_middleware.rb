module EtCcdExport
  module Sidekiq
    module Middleware
      class MultiplesClientMiddleware

        # @param [String, Class] worker_class the string or class of the worker class being enqueued
        # @param [Hash] job the full job payload
        #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
        # @param [String] queue the name of the queue the job was pulled from
        # @param [ConnectionPool] redis_pool the redis pool
        # @return [Hash, FalseClass, nil] if false or nil is returned,
        #   the job is not to be enqueued into redis, otherwise the block's
        #   return value is returned
        # @yield the next middleware in the chain or the enqueuing of the job
        def call(_worker_class, job, _queue, _redis_pool)
          return yield if Thread.current[:et_ccd_export_multiple_batch].nil?

          job['et_ccd_export_multiple_batch_reference'] = Thread.current[:et_ccd_export_multiple_batch].reference
          batch = EtCcdExport::Sidekiq::Batch.find(Thread.current[:et_ccd_export_multiple_batch].reference)
          add_to_todo(job, batch)
          yield
        end

        private

        def add_to_todo(job, batch)
          return if Thread.current[:et_ccd_export_multiple_batch_child_reference].nil?

          job['et_ccd_export_multiple_batch_child_reference'] = Thread.current[:et_ccd_export_multiple_batch_child_reference]
          batch.add_child_to_todo(Thread.current[:et_ccd_export_multiple_batch_child_reference])
        end
      end
    end
  end
end
