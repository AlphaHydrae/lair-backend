# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140913130401) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "item_descriptions", force: true do |t|
    t.integer "item_id",     null: false
    t.integer "language_id", null: false
    t.text    "contents",    null: false
  end

  create_table "item_parts", force: true do |t|
    t.string   "type",           limit: 5,  null: false
    t.integer  "item_id",                   null: false
    t.integer  "item_title_id",             null: false
    t.integer  "range_start"
    t.integer  "range_end"
    t.integer  "language_id",               null: false
    t.string   "edition"
    t.string   "edition_number"
    t.string   "format"
    t.integer  "length"
    t.string   "publisher"
    t.string   "isbn10",         limit: 10
    t.string   "isbn13",         limit: 13
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "item_parts", ["isbn10"], name: "index_item_parts_on_isbn10", unique: true, using: :btree
  add_index "item_parts", ["isbn13"], name: "index_item_parts_on_isbn13", unique: true, using: :btree

  create_table "item_people", force: true do |t|
    t.integer "item_id",                 null: false
    t.integer "person_id",               null: false
    t.string  "relationship", limit: 20, null: false
  end

  create_table "item_titles", force: true do |t|
    t.integer "item_id",          null: false
    t.integer "language_id",      null: false
    t.string  "contents",         null: false
    t.integer "display_position", null: false
  end

  create_table "item_urls", force: true do |t|
    t.string  "contents",    null: false
    t.integer "item_id",     null: false
    t.integer "language_id"
  end

  add_index "item_urls", ["item_id", "contents"], name: "index_item_urls_on_item_id_and_contents", unique: true, using: :btree

  create_table "items", force: true do |t|
    t.string   "category",          limit: 10, null: false
    t.integer  "number_of_parts"
    t.integer  "original_title_id"
    t.integer  "start_year",                   null: false
    t.integer  "end_year",                     null: false
    t.integer  "language_id",                  null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "items", ["category"], name: "index_items_on_category", using: :btree

  create_table "languages", force: true do |t|
    t.string "iso_code", limit: 5, null: false
  end

  add_index "languages", ["iso_code"], name: "index_languages_on_iso_code", unique: true, using: :btree

  create_table "ownerships", force: true do |t|
    t.integer  "item_id",   null: false
    t.integer  "user_id",   null: false
    t.datetime "gotten_at", null: false
  end

  create_table "people", force: true do |t|
    t.string "last_name"
    t.string "first_names"
    t.string "pseudonym"
  end

  create_table "users", force: true do |t|
    t.string   "email",              limit: 255,             null: false
    t.integer  "sign_in_count",                  default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  add_foreign_key "item_descriptions", "items"
  add_foreign_key "item_parts", "item_titles"
  add_foreign_key "item_parts", "items"
  add_foreign_key "item_parts", "languages"
  add_foreign_key "item_people", "items"
  add_foreign_key "item_people", "people"
  add_foreign_key "item_titles", "items"
  add_foreign_key "item_titles", "languages"
  add_foreign_key "item_urls", "items"
  add_foreign_key "item_urls", "languages"
  add_foreign_key "items", "item_titles", column: "original_title_id"
  add_foreign_key "items", "languages"
  add_foreign_key "ownerships", "items"
  add_foreign_key "ownerships", "users"
end
