# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_03_094111) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "et_ccd_export_batches", force: :cascade do |t|
    t.jsonb "callbacks", default: []
    t.string "case_type_id"
    t.datetime "created_at", null: false
    t.string "done_references", default: [], array: true
    t.string "error_references", default: [], array: true
    t.integer "export_id"
    t.string "failed_references", default: [], array: true
    t.string "in_progress_references", default: [], array: true
    t.string "quantity"
    t.string "reference"
    t.string "start_ref"
    t.string "todo_references", default: [], array: true
    t.datetime "updated_at", null: false
  end
end
