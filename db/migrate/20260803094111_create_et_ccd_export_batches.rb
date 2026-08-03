class CreateEtCcdExportBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :et_ccd_export_batches do |t|
      t.string :reference
      t.string :quantity
      t.string :start_ref
      t.integer :export_id
      t.string :case_type_id
      t.jsonb :callbacks, default: []
      t.string :todo_references, array: true, default: []
      t.string :in_progress_references, array: true, default: []
      t.string :done_references, array: true, default: []
      t.string :failed_references, array: true, default: []
      t.string :error_references, array: true, default: []

      t.timestamps
    end
  end
end
