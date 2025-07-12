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

ActiveRecord::Schema[8.0].define(version: 2025_07_12_091246) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "page_views", force: :cascade do |t|
    t.bigint "visit_id", null: false
    t.string "path"
    t.datetime "viewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_page_views_on_path"
    t.index ["viewed_at", "path"], name: "index_page_views_on_viewed_at_and_path"
    t.index ["viewed_at"], name: "index_page_views_on_viewed_at"
    t.index ["visit_id"], name: "index_page_views_on_visit_id"
  end

  create_table "visitors", force: :cascade do |t|
    t.string "uuid"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "first_visit_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_visitors_on_uuid", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.bigint "visitor_id", null: false
    t.string "page_path"
    t.string "referrer"
    t.string "device_type"
    t.string "source_type"
    t.string "country_code"
    t.string "region"
    t.string "city"
    t.integer "duration"
    t.boolean "bounced"
    t.datetime "entered_at"
    t.datetime "exited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page_views_count", default: 0, null: false
    t.string "site_url"
    t.string "app_name"
    t.index ["bounced"], name: "index_visits_on_bounced"
    t.index ["country_code"], name: "index_visits_on_country_code"
    t.index ["device_type"], name: "index_visits_on_device_type"
    t.index ["entered_at", "bounced"], name: "index_visits_on_entered_at_and_bounced"
    t.index ["entered_at", "country_code"], name: "index_visits_on_entered_at_and_country_code"
    t.index ["entered_at"], name: "index_visits_on_entered_at"
    t.index ["source_type"], name: "index_visits_on_source_type"
    t.index ["visitor_id"], name: "index_visits_on_visitor_id"
  end

  add_foreign_key "page_views", "visits"
  add_foreign_key "visits", "visitors"
end
