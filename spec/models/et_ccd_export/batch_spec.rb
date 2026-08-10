require 'rails_helper'

RSpec.describe EtCcdExport::Batch do
  subject(:batch) { described_class.new(reference: 'main-reference-00001', quantity: '10', start_ref: 'child-reference-00001', export_id: '1', case_type_id: 'fakecasetypeid') }

  describe '#save' do
    it 'saves the batch' do
      batch.save
      expect(batch).to be_persisted
    end
  end

  describe '#destroy' do
    it 'destroys the batch' do
      batch.save
      batch.destroy
      expect(batch).not_to be_persisted
    end
  end

  describe '.find' do
    it 'finds the batch' do
      batch.save
      found_batch = described_class.find(batch.reference)
      expect(found_batch).to eq(batch)
    end
  end

  describe '.start' do
    it 'creates a new batch and saves it' do
      batch = described_class.start(reference: 'main-reference-00001', quantity: '10', start_ref: 'child-reference-00001', export_id: '1', case_type_id: 'fakecasetypeid')
      expect(batch).to be_persisted
    end
  end

  describe '.on' do
    it 'adds a callback to the batch' do
      batch.save
      stub_const('ExampleCallback', Class.new)
      batch.on(:success, ExampleCallback, 'example_arg_value')
      expect(batch.callbacks).to include(a_hash_including('class_name' => 'ExampleCallback', 'event' => 'success', 'args' => ['example_arg_value']))
    end
  end

  describe '#callbacks' do
    it 'returns the callbacks for the batch' do
      batch.save
      stub_const('ExampleCallback', Class.new)
      stub_const('ExampleCallback2', Class.new)
      batch.on(:success, ExampleCallback, 'example_arg_value')
      batch.on(:success, ExampleCallback2, 'example_arg_value2')
      expect(batch.callbacks).
        to include(
          a_hash_including('class_name' => 'ExampleCallback', 'event' => 'success', 'args' => ['example_arg_value']),
          a_hash_including('class_name' => 'ExampleCallback2', 'event' => 'success', 'args' => ['example_arg_value2'])
        )
    end
  end

  describe '#jobs' do
    it 'yields with the et_ccd_export_multiple_batch set in the current thread' do
      previous_value = Thread.current[:et_ccd_export_multiple_batch]
      previous_batch = described_class.new(reference: 'main-reference-00002', quantity: '10', start_ref: 'child-reference-10002', export_id: '2', case_type_id: 'fakecasetypeid')
      yielded_batch = nil
      Thread.current[:et_ccd_export_multiple_batch] = previous_batch
      batch.jobs do
        yielded_batch = Thread.current[:et_ccd_export_multiple_batch]
      end
      aggregate_failures 'validate batch and thread state' do
        expect(yielded_batch).to eq(batch)
        expect(Thread.current[:et_ccd_export_multiple_batch]).to eq(previous_batch)
      end
    ensure
      Thread.current[:et_ccd_export_multiple_batch] = previous_value
    end
  end

  describe '#child_job' do
    it 'yields with the et_ccd_export_multiple_batch_child_reference set in the current thread' do
      previous_value = Thread.current[:et_ccd_export_multiple_batch_child_reference]
      previous_child_reference = 'child-reference-10002'
      yielded_child_reference = nil
      Thread.current[:et_ccd_export_multiple_batch_child_reference] = previous_child_reference
      batch.child_job('child-reference-10002') do
        yielded_child_reference = Thread.current[:et_ccd_export_multiple_batch_child_reference]
      end
      aggregate_failures 'validate child reference and thread state' do
        expect(yielded_child_reference).to eq('child-reference-10002')
        expect(Thread.current[:et_ccd_export_multiple_batch_child_reference]).to eq(previous_child_reference)
      end
    ensure
      Thread.current[:et_ccd_export_multiple_batch_child_reference] = previous_value
    end
  end

  describe '#percent_complete' do
    before { batch.save }

    it 'is zero to start with' do
      expect(batch.percent_complete).to eq(0)
    end

    it 'is 33 when 2 jobs are complete out of 5 in todo (calculation bug - but not changing yet)' do
      5.times do |i|
        batch.add_child_to_todo("child-reference-0000#{i + 1}")
      end
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00002')
      batch.move_child_to_done('child-reference-00001')
      batch.move_child_to_done('child-reference-00002')
      expect(batch.percent_complete).to eq(33)
    end

    it 'is 33 when 2 jobs are complete out of 4 in todo and 1 error (calculation bug - but not changing yet)' do
      5.times do |i|
        batch.add_child_to_todo("child-reference-0000#{i + 1}")
      end
      batch.move_child_to_in_progress("child-reference-00001")
      batch.move_child_to_in_progress("child-reference-00002")
      batch.move_child_to_in_progress("child-reference-00004")

      batch.move_child_to_error('child-reference-00004')
      batch.move_child_to_done('child-reference-00001')
      batch.move_child_to_done('child-reference-00002')
      expect(batch.percent_complete).to eq(33)
    end

    it 'ignores in progress jobs when calculating percent complete (bug I think)' do
      5.times do |i|
        batch.add_child_to_todo("child-reference-0000#{i + 1}")
      end
      batch.move_child_to_in_progress("child-reference-00001")
      batch.move_child_to_in_progress("child-reference-00002")
      batch.move_child_to_done("child-reference-00001")
      expect(batch.percent_complete).to eq(20)
    end

  end

  describe '#add_child_to_todo' do
    before { batch.save! }

    it 'adds the child reference to todo_references' do
      batch.add_child_to_todo('child-reference-00001')
      expect(batch.todo_references).to eq(['child-reference-00001'])
    end
  end

  describe '#move_child_to_in_progress' do
    before { batch.save! }

    it 'moves the child reference from todo to in progress' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      aggregate_failures 'validate batch state' do
        expect(batch.in_progress_references).to eq(['child-reference-00001'])
        expect(batch.todo_references).to eq([])
      end
    end

    it 'moves the child reference from error to in progress when it is not in todo' do
      batch.update!(error_references: ['child-reference-00001'])

      batch.move_child_to_in_progress('child-reference-00001')

      aggregate_failures 'validate batch state' do
        expect(batch.in_progress_references).to eq(['child-reference-00001'])
        expect(batch.error_references).to eq([])
      end
    end

    it 'does nothing when the child reference is not in todo or error' do
      expect { batch.move_child_to_in_progress('child-reference-00001') }.
        not_to(change { batch.reload.attributes.slice('todo_references', 'error_references', 'in_progress_references') })
    end
  end

  describe '#move_child_to_done' do
    before { batch.save! }

    it 'moves the child reference from in progress to done' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_done('child-reference-00001')
      aggregate_failures 'validate batch state' do
        expect(batch.done_references).to eq(['child-reference-00001'])
        expect(batch.in_progress_references).to eq([])
      end
    end

    it 'moves the child reference from error to done' do
      batch.update!(error_references: ['child-reference-00001'])

      batch.move_child_to_done('child-reference-00001')

      aggregate_failures 'validate batch state' do
        expect(batch.done_references).to eq(['child-reference-00001'])
        expect(batch.error_references).to eq([])
        expect(batch.in_progress_references).to eq([])
      end
    end
  end

  describe '#move_child_to_error' do
    before { batch.save! }

    it 'moves the child reference from in progress to error' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      aggregate_failures 'validate batch state' do
        expect(batch.error_references).to eq(['child-reference-00001'])
        expect(batch.in_progress_references).to eq([])
      end
    end

    it 'is idempotent' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      aggregate_failures 'validate batch state' do
        expect(batch.error_references).to eq(['child-reference-00001'])
        expect(batch.in_progress_references).to eq([])
      end
    end

  end

  describe '#move_child_to_failed' do
    before { batch.save! }

    it 'moves the child reference from error to failed' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      batch.move_child_to_failed('child-reference-00001')
      aggregate_failures 'validate batch state' do
        expect(batch.failed_references).to eq(['child-reference-00001'])
        expect(batch.error_references).to eq([])
        expect(batch.in_progress_references).to eq([])
      end
    end

    it 'moves the child reference from in progress to failed' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_failed('child-reference-00001')
      aggregate_failures 'validate batch state' do
        expect(batch.failed_references).to eq(['child-reference-00001'])
        expect(batch.in_progress_references).to eq([])
      end
    end

  end

  describe '#done_references' do
    before { batch.save! }

    it 'is empty to start with' do
      expect(batch.done_references).to eq([])
    end

    it 'returns any references that have been moved to done' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_done('child-reference-00001')
      expect(batch.done_references).to eq(['child-reference-00001'])
    end
  end

  describe '#error_references' do
    before { batch.save! }

    it 'is empty to start with' do
      expect(batch.error_references).to eq([])
    end

    it 'returns any references that have been moved to error' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      expect(batch.error_references).to eq(['child-reference-00001'])
    end
  end

  describe '#failed_references' do
    before { batch.save! }

    it 'is empty to start with' do
      expect(batch.failed_references).to eq([])
    end

    it 'returns any references that have been moved to failed' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      batch.move_child_to_failed('child-reference-00001')
      expect(batch.failed_references).to eq(['child-reference-00001'])
    end
  end

  describe '#todo_references' do
    before { batch.save! }

    it 'is empty to start with' do
      expect(batch.todo_references).to eq([])
    end

    it 'returns any references that have been added to todo' do
      batch.add_child_to_todo('child-reference-00001')
      expect(batch.todo_references).to eq(['child-reference-00001'])
    end
  end

  describe '#persisted?' do
    it 'is false to start with' do
      expect(batch.persisted?).to be false
    end

    it 'is true after save' do
      batch.save
      expect(batch.persisted?).to be true
    end
  end

  describe '#more_work_to_be_done?' do
    before { batch.save! }

    it 'is false to start with' do
      expect(batch.more_work_to_be_done?).to be false
    end

    it 'is true if there is an item in todo' do
      batch.add_child_to_todo('child-reference-00001')
      expect(batch.more_work_to_be_done?).to be true
    end

    it 'is true if there is an item in in_progress' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      expect(batch.more_work_to_be_done?).to be true
    end

    it 'is true if there is an item in error' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
    end

    it 'is false if all have moved to done' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_done('child-reference-00001')
      expect(batch.more_work_to_be_done?).to be false
    end

    it 'is false if all have moved to failed' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      batch.move_child_to_failed('child-reference-00001')
      expect(batch.more_work_to_be_done?).to be false
    end
  end

  describe '#failed?' do
    before { batch.save! }

    it 'is false to start with' do
      expect(batch.failed?).to be false
    end

    it 'is false if an item is in error' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      expect(batch.failed?).to be false
    end

    it 'is true if an item is in failed' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      batch.move_child_to_failed('child-reference-00001')
      expect(batch.failed?).to be true
    end

    it 'is false if an item is in failed and one is in todo' do
      batch.add_child_to_todo('child-reference-00001')
      batch.move_child_to_in_progress('child-reference-00001')
      batch.move_child_to_error('child-reference-00001')
      batch.move_child_to_failed('child-reference-00001')
      batch.add_child_to_todo('child-reference-00002')
      expect(batch.failed?).to be false
    end
  end

end
