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

  create_table "image_searches", force: :cascade do |t|
    t.string   "api_id",         limit: 12,  null: false
    t.integer  "imageable_id"
    t.string   "imageable_type", limit: 25
    t.string   "engine",         limit: 25,  null: false
    t.string   "query",          limit: 255, null: false
    t.json     "results",                    null: false
    t.integer  "results_count",              null: false
    t.integer  "user_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "images", force: :cascade do |t|
    t.string   "api_id",                 limit: 12,  null: false
    t.string   "url",                    limit: 255, null: false
    t.string   "content_type",           limit: 50,  null: false
    t.integer  "width"
    t.integer  "height"
    t.integer  "size"
    t.string   "thumbnail_url",          limit: 255
    t.string   "thumbnail_content_type", limit: 50
    t.integer  "thumbnail_width"
    t.integer  "thumbnail_height"
    t.integer  "thumbnail_size"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "item_descriptions", force: :cascade do |t|
    t.string  "api_id",      limit: 12, null: false
    t.integer "item_id",                null: false
    t.integer "language_id",            null: false
    t.text    "contents",               null: false
  end

  add_index "item_descriptions", ["api_id"], name: "index_item_descriptions_on_api_id", unique: true, using: :btree

  create_table "item_links", force: :cascade do |t|
    t.string  "url",         limit: 255, null: false
    t.integer "item_id",                 null: false
    t.integer "language_id"
  end

  add_index "item_links", ["item_id", "url"], name: "index_item_links_on_item_id_and_url", unique: true, using: :btree

  create_table "item_parts", force: :cascade do |t|
    t.string   "api_id",                   limit: 12,  null: false
    t.string   "type",                     limit: 5,   null: false
    t.integer  "item_id",                              null: false
    t.integer  "title_id"
    t.integer  "image_id"
    t.integer  "main_image_search_id"
    t.string   "custom_title",             limit: 150
    t.integer  "custom_title_language_id"
    t.string   "effective_title",          limit: 200, null: false
    t.integer  "year"
    t.integer  "original_year",                        null: false
    t.integer  "range_start"
    t.integer  "range_end"
    t.integer  "language_id",                          null: false
    t.string   "edition",                  limit: 25
    t.integer  "version"
    t.string   "format",                   limit: 25
    t.integer  "length"
    t.json     "tags"
    t.string   "publisher",                limit: 50
    t.string   "isbn",                     limit: 13
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "item_parts", ["api_id"], name: "index_item_parts_on_api_id", unique: true, using: :btree
  add_index "item_parts", ["isbn"], name: "index_item_parts_on_isbn", unique: true, using: :btree

  create_table "item_people", force: :cascade do |t|
    t.integer "item_id",                 null: false
    t.integer "person_id",               null: false
    t.string  "relationship", limit: 20, null: false
  end

  create_table "item_titles", force: :cascade do |t|
    t.string  "api_id",           limit: 12,  null: false
    t.integer "item_id",                      null: false
    t.integer "language_id",                  null: false
    t.string  "contents",         limit: 150, null: false
    t.integer "display_position",             null: false
  end

  add_index "item_titles", ["api_id"], name: "index_item_titles_on_api_id", unique: true, using: :btree

  create_table "items", force: :cascade do |t|
    t.string   "api_id",               limit: 6,  null: false
    t.string   "category",             limit: 10, null: false
    t.integer  "number_of_parts"
    t.integer  "original_title_id"
    t.integer  "start_year"
    t.integer  "end_year"
    t.integer  "language_id",                     null: false
    t.integer  "image_id"
    t.integer  "main_image_search_id"
    t.json     "tags"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "items", ["api_id"], name: "index_items_on_api_id", unique: true, using: :btree
  add_index "items", ["category"], name: "index_items_on_category", using: :btree

  create_table "languages", force: :cascade do |t|
    t.string "tag", limit: 5, null: false
  end

  add_index "languages", ["tag"], name: "index_languages_on_tag", unique: true, using: :btree

  create_table "ownerships", force: :cascade do |t|
    t.string   "api_id",       limit: 12, null: false
    t.integer  "item_part_id",            null: false
    t.integer  "user_id",                 null: false
    t.json     "tags"
    t.datetime "gotten_at",               null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "people", force: :cascade do |t|
    t.string   "api_id",      limit: 12,  null: false
    t.string   "last_name",   limit: 50
    t.string   "first_names", limit: 100
    t.string   "pseudonym",   limit: 50
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "api_id",        limit: 12,              null: false
    t.string   "email",         limit: 255,             null: false
    t.integer  "sign_in_count",             default: 0, null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "users", ["api_id"], name: "index_users_on_api_id", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  add_foreign_key "image_searches", "users"
  add_foreign_key "item_descriptions", "items"
  add_foreign_key "item_links", "items"
  add_foreign_key "item_links", "languages"
  add_foreign_key "item_parts", "image_searches", column: "main_image_search_id"
  add_foreign_key "item_parts", "images"
  add_foreign_key "item_parts", "item_titles", column: "title_id"
  add_foreign_key "item_parts", "items"
  add_foreign_key "item_parts", "languages"
  add_foreign_key "item_parts", "languages", column: "custom_title_language_id"
  add_foreign_key "item_people", "items"
  add_foreign_key "item_people", "people"
  add_foreign_key "item_titles", "items"
  add_foreign_key "item_titles", "languages"
  add_foreign_key "items", "image_searches", column: "main_image_search_id"
  add_foreign_key "items", "images"
  add_foreign_key "items", "item_titles", column: "original_title_id"
  add_foreign_key "items", "languages"
  add_foreign_key "ownerships", "item_parts"
  add_foreign_key "ownerships", "users"
end
