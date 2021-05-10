require 'et_ccd_export/sidekiq/middleware/multiples_middleware'
require 'et_ccd_export/sidekiq/middleware/multiples_client_middleware'
module EtCcdExport
  module Sidekiq
    class Batch
      attr_reader :reference, :quantity, :start_ref, :export_id, :case_type_id

      def initialize(reference:, quantity:, start_ref:, export_id:, case_type_id:, sidekiq: ::Sidekiq)
        @reference = reference
        @quantity = quantity
        @start_ref = start_ref
        @sidekiq = sidekiq
        @export_id = export_id.to_i
        @case_type_id = case_type_id
      end

      def save
        sidekiq.redis do |r|
          r.hset(redis_key, *as_json(except: 'sidekiq').flatten)
        end
      end

      def destroy
        sidekiq.redis do |r|
          r.del(redis_key)
          r.del(callbacks_key)
          r.del(done_redis_key)
          r.del(failed_redis_key)
          r.del(error_redis_key)
          r.del(todo_redis_key)
          r.del(in_progress_redis_key)
        end
      end

      def self.find(reference, sidekiq: ::Sidekiq)
        sidekiq.redis do |r|
          results = r.hgetall(redis_key(reference))
          raise BatchNotFoundException, "Batch with reference #{reference} was not found in redis" if results.empty?

          new(**results.symbolize_keys)
        end
      end

      def self.start(**args)
        new(**args).tap(&:save)
      end

      def on(event, callback_class, *args)
        callback =  {
          class_name: callback_class.name,
          event: event,
          args: args
        }
        sidekiq.redis do |r|
          r.rpush(callbacks_key, callback.to_json)
        end
      end

      def callbacks
        sidekiq.redis do |r|
          r.lrange(callbacks_key, 0, r.llen(callbacks_key)).map { |callback| JSON.parse(callback) }
        end
      end

      def jobs
        old_multiple_batch = Thread.current[:et_ccd_export_multiple_batch]
        Thread.current[:et_ccd_export_multiple_batch] = self
        yield
        self
      ensure
        Thread.current[:et_ccd_export_multiple_batch] = old_multiple_batch
      end

      def child_job(reference)
        old_multiple_child_reference = Thread.current[:et_ccd_export_multiple_batch_child_reference]
        Thread.current[:et_ccd_export_multiple_batch_child_reference] = reference
        yield
        self
      ensure
        Thread.current[:et_ccd_export_multiple_batch_child_reference] = old_multiple_child_reference
      end

      def percent_complete
        sidekiq.redis do |r|
          done = r.scard(done_redis_key)
          not_done = r.scard(todo_redis_key) + r.scard(error_redis_key) + r.scard(failed_redis_key)
          (done * (100.0 / (done + not_done + 1))).to_i
        end
      end

      def add_child_to_todo(child_reference)
        sidekiq.redis do |r|
          r.sadd(todo_redis_key, child_reference)
        end
      end

      def move_child_to_in_progress(child_reference)
        sidekiq.redis do |r|
          r.smove(todo_redis_key, in_progress_redis_key, child_reference) ||
          r.smove(error_redis_key, in_progress_redis_key, child_reference)
        end
      end

      def move_child_to_done(child_reference)
        sidekiq.redis do |r|
          r.smove(in_progress_redis_key, done_redis_key, child_reference) ||
          r.smove(error_redis_key, done_redis_key, child_reference)
        end
      end

      def move_child_to_error(child_reference)
        sidekiq.redis do |r|
          r.smove in_progress_redis_key, error_redis_key, child_reference unless r.sismember(error_redis_key, child_reference)
        end
      end

      def move_child_to_failed(child_reference)
        sidekiq.redis do |r|
          r.smove(error_redis_key, failed_redis_key, child_reference) ||
            r.smove(in_progress_redis_key, failed_redis_key, child_reference)
        end
      end

      def done_count
        sidekiq.redis do |r|
          r.scard(done_redis_key)
        end
      end

      def todo_count
        sidekiq.redis do |r|
          r.scard(todo_redis_key)
        end
      end

      def in_progress_count
        sidekiq.redis do |r|
          r.scard(in_progress_redis_key)
        end
      end

      def error_count
        sidekiq.redis do |r|
          r.scard(error_redis_key)
        end
      end

      def failed_count
        sidekiq.redis do |r|
          r.scard(failed_redis_key)
        end
      end

      def done_references
        sidekiq.redis do |r|
          r.smembers(done_redis_key).sort do |a, b|
            next -1 if a == start_ref

            a <=> b
          end
        end
      end

      def error_references
        sidekiq.redis do |r|
          r.smembers(error_redis_key)
        end
      end

      def failed_references
        sidekiq.redis do |r|
          r.smembers(failed_redis_key)
        end
      end

      def todo_references
        sidekiq.redis do |r|
          r.smembers(todo_redis_key)
        end
      end

      def persisted?
        sidekiq.redis do |r|
          r.exists?(redis_key)
        end
      end

      def more_work_to_be_done?
        todo_count.positive? || in_progress_count.positive? || error_count.positive?
      end

      def failed?
        !more_work_to_be_done? && failed_count.positive?
      end

      private

      attr_reader :sidekiq


      def redis_key
        self.class.redis_key(reference)
      end

      def todo_redis_key
        "#{redis_key}-todo"
      end

      def in_progress_redis_key
        "#{redis_key}-in-progress"
      end

      def done_redis_key
        "#{redis_key}-done"
      end

      def error_redis_key
        "#{redis_key}-error"
      end

      def failed_redis_key
        "#{redis_key}-failed"
      end

      def callbacks_key
        "#{redis_key}-callbacks"
      end

      def self.redis_key(reference)
        "et_ccd_export-multiple-#{reference}"
      end
    end
  end
end
