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

ActiveRecord::Schema[8.0].define(version: 2025_07_19_184123) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "authentication_providers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider"
    t.string "uid"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_authentication_providers_on_user_id"
  end

  create_table "domains", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_domains_on_user_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "name"
    t.boolean "is_long_tail"
    t.bigint "keyword_id"
    t.integer "search_intent", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "domain_id", null: false
    t.index ["domain_id"], name: "index_keywords_on_domain_id"
    t.index ["keyword_id"], name: "index_keywords_on_keyword_id"
  end

  create_table "linkedin_contents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content"
    t.integer "status", default: 0
    t.string "ai_model"
    t.bigint "prompt_id", null: false
    t.string "cta_url"
    t.string "keyword"
    t.jsonb "linkedin_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prompt_id"], name: "index_linkedin_contents_on_prompt_id"
    t.index ["user_id"], name: "index_linkedin_contents_on_user_id"
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

  create_table "prompts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "target", default: 0, null: false
    t.text "user_prompt"
    t.text "system_prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_prompts_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fetchserp_api_key"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "wordpress_contents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "content"
    t.integer "status", default: 0, null: false
    t.string "keyword"
    t.string "cta_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "prompt_id", null: false
    t.string "ai_model"
    t.jsonb "wp_response"
    t.boolean "publish_on_create", default: false
    t.index ["prompt_id"], name: "index_wordpress_contents_on_prompt_id"
    t.index ["user_id"], name: "index_wordpress_contents_on_user_id"
  end

  create_table "wordpress_websites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "url"
    t.string "username"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wordpress_websites_on_user_id"
  end

  add_foreign_key "authentication_providers", "users"
  add_foreign_key "domains", "users"
  add_foreign_key "keywords", "domains"
  add_foreign_key "keywords", "keywords"
  add_foreign_key "linkedin_contents", "prompts"
  add_foreign_key "linkedin_contents", "users"
  add_foreign_key "pages", "keywords"
  add_foreign_key "prompts", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "wordpress_contents", "prompts"
  add_foreign_key "wordpress_contents", "users"
  add_foreign_key "wordpress_websites", "users"
end
