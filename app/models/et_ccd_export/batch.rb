module EtCcdExport
  class Batch < ApplicationRecord
    self.table_name = 'et_ccd_export_batches'

    STATE_COLUMNS = %i[
      callbacks
      todo_references
      in_progress_references
      done_references
      failed_references
      error_references
    ].freeze

    STATE_COLUMNS.each do |column|
      define_method(column) do
        state_snapshot.fetch(column)
      end
    end

    def self.find(reference)
      find_by(reference:)
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
      add_callback(callback)
      reload
    end

    def add_callback(callback)
      self.class.
        where(id: id).
        update_all(
          [
            "callbacks = COALESCE(callbacks, '[]'::jsonb) || ?::jsonb",
            [callback].to_json
          ]
        )
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
      state = state_snapshot
      done = state[:done_references].length
      not_done = state[:todo_references].length + state[:error_references].length + state[:failed_references].length
      (done * (100.0 / (done + not_done + 1))).to_i
    end

    def state_snapshot
      return STATE_COLUMNS.index_with { |column| self[column] } if new_record?

      values = self.class.uncached do
        self.class.where(id: id).pick(*STATE_COLUMNS)
      end

      raise ActiveRecord::RecordNotFound, "Batch #{id} no longer exists" unless values

      STATE_COLUMNS.zip(values).to_h
    end

    def add_child_to_todo(child_reference)
      self.class.
        where(id: id).
        update_all(
          [
            <<~SQL.squish,
              todo_references =
                CASE
                  WHEN ? = ANY(todo_references)
                  THEN todo_references
                  ELSE array_append(todo_references, ?)
                END
            SQL
            child_reference,
            child_reference
          ]
        )

      reload
      self
    end

    def move_child_to_in_progress(child_reference)
      move_child_reference(
        child_reference,
        from: [:todo_references, :error_references],
        to: :in_progress_references
      )
    end

    def move_child_to_done(child_reference)
      move_child_reference(
        child_reference,
        from: [:in_progress_references, :error_references],
        to: :done_references
      )
    end

    def move_child_to_error(child_reference)
      move_child_reference(
        child_reference,
        from: [:in_progress_references],
        to: :error_references
      )
    end

    def move_child_to_failed(child_reference)
      move_child_reference(
        child_reference,
        from: [:error_references, :in_progress_references],
        to: :failed_references
      )
    end

    def more_work_to_be_done?
      state = state_snapshot
      state[:todo_references].present? || state[:in_progress_references].present? || state[:error_references].present?
    end

    def failed?
      state = state_snapshot
      no_work_remaining =
        state[:todo_references].empty? &&
        state[:in_progress_references].empty? &&
        state[:error_references].empty?

      no_work_remaining && state[:failed_references].present?
    end

    private

    def move_child_reference(child_reference, from:, to:)
      with_lock do
        source = from.find { |column| self[column].include?(child_reference) }
        next unless source

        update_columns(
          source => self[source] - [child_reference],
          to => self[to] | [child_reference],
          updated_at: Time.current
        )
      end

      reload
    end

  end
end
