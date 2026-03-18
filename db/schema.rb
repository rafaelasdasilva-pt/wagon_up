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

ActiveRecord::Schema[8.1].define(version: 2026_03_18_185912) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analyses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "cv_text"
    t.jsonb "raw_json"
    t.text "skills"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_analyses_on_user_id"
  end

  create_table "interview_answers", force: :cascade do |t|
    t.text "answer"
    t.datetime "created_at", null: false
    t.text "feedback"
    t.bigint "interview_session_id", null: false
    t.integer "position"
    t.text "question"
    t.integer "score"
    t.datetime "updated_at", null: false
    t.index ["interview_session_id"], name: "index_interview_answers_on_interview_session_id"
  end

  create_table "interview_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "feedback_summary"
    t.integer "overall_score"
    t.bigint "suggested_role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["suggested_role_id"], name: "index_interview_sessions_on_suggested_role_id"
    t.index ["user_id"], name: "index_interview_sessions_on_user_id"
  end

  create_table "suggested_roles", force: :cascade do |t|
    t.bigint "analysis_id", null: false
    t.datetime "created_at", null: false
    t.text "justification"
    t.jsonb "market_fit"
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["analysis_id"], name: "index_suggested_roles_on_analysis_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "analyses", "users"
  add_foreign_key "interview_answers", "interview_sessions"
  add_foreign_key "interview_sessions", "suggested_roles"
  add_foreign_key "interview_sessions", "users"
  add_foreign_key "suggested_roles", "analyses"
end
