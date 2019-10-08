class PreventJobRetryingException < ApplicationException
  def initialize(msg, job_hash)
    super(msg)
    self.job_hash = job_hash.slice('error_class', 'error_message', 'retried_at')
  end

  attr_accessor :job_hash

end
