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

ActiveRecord::Schema[7.1].define(version: 2025_10_28_152358) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "budgets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.decimal "pessimistic_amount"
    t.decimal "realistic_amount"
    t.decimal "optimistic_amount"
    t.decimal "actual_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.string "category_type", default: "expense", null: false
    t.index ["category_type"], name: "index_categories_on_category_type"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.bigint "checklist_id", null: false
    t.string "content"
    t.boolean "done"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_id"], name: "index_checklist_items_on_checklist_id"
  end

  create_table "checklists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_checklists_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount"
    t.text "description"
    t.date "date"
    t.string "receipt_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.decimal "target_amount"
    t.decimal "current_amount"
    t.date "deadline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "goal_type"
    t.bigint "category_id"
    t.string "period"
    t.string "reduction_type"
    t.decimal "reduction_value"
    t.date "start_date"
    t.date "end_date"
    t.index ["category_id"], name: "index_goals_on_category_id"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "prediction_categories", force: :cascade do |t|
    t.bigint "prediction_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_prediction_categories_on_category_id"
    t.index ["prediction_id"], name: "index_prediction_categories_on_prediction_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "scenario_name"
    t.jsonb "forecast_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "base_start_date"
    t.date "base_end_date"
    t.date "forecast_start_date"
    t.date "forecast_end_date"
    t.index ["user_id"], name: "index_predictions_on_user_id"
  end

  create_table "reconciliations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "bank_file_name"
    t.string "status"
    t.jsonb "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["user_id"], name: "index_reconciliations_on_user_id"
  end

  create_table "revenues", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount"
    t.string "category"
    t.text "description"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_revenues_on_category_id"
    t.index ["user_id"], name: "index_revenues_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "reconciliation_id", null: false
    t.date "date"
    t.string "description"
    t.decimal "amount"
    t.decimal "match_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "matchable_type"
    t.bigint "matchable_id"
    t.index ["matchable_type", "matchable_id"], name: "index_transactions_on_matchable"
    t.index ["reconciliation_id"], name: "index_transactions_on_reconciliation_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "checklist_items", "checklists"
  add_foreign_key "checklists", "users"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "goals", "categories"
  add_foreign_key "goals", "users"
  add_foreign_key "prediction_categories", "categories"
  add_foreign_key "prediction_categories", "predictions"
  add_foreign_key "predictions", "users"
  add_foreign_key "reconciliations", "users"
  add_foreign_key "revenues", "categories"
  add_foreign_key "revenues", "users"
  add_foreign_key "transactions", "reconciliations"
end
