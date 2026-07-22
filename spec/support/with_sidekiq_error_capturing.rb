module EtExporter
  module Test
    class SidekiqErrorCapturing
      def call(_worker, msg, _queue)
        yield
      rescue StandardError => e
        msg['queue'] = 'retry'
        msg['error_message'] = e.message
        msg['error_class'] = e.class.to_s
        if msg["retry_count"]
          msg["retried_at"] = Time.now.to_f
          msg["retry_count"] += 1
        else
          msg["failed_at"] = Time.now.to_f
          msg["retry_count"] = 0
        end
      end
    end
  end
end
