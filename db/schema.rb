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

ActiveRecord::Schema[8.0].define(version: 2025_07_07_161946) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "keywords", force: :cascade do |t|
    t.string "name"
    t.boolean "is_long_tail"
    t.bigint "keyword_id"
    t.integer "search_intent", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["keyword_id"], name: "index_keywords_on_keyword_id"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "keyword_id", null: false
    t.string "slug"
    t.text "meta_title"
    t.text "meta_description"
    t.text "headline"
    t.text "subheading"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["keyword_id"], name: "index_pages_on_keyword_id"
  end

  add_foreign_key "keywords", "keywords"
  add_foreign_key "pages", "keywords"
end
