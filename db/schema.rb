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

ActiveRecord::Schema.define(version: 20160508132054) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collection_items", force: :cascade do |t|
    t.string   "api_id",        limit: 12, null: false
    t.integer  "collection_id",            null: false
    t.integer  "item_id",                  null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "collection_items", ["api_id"], name: "index_collection_items_on_api_id", unique: true, using: :btree
  add_index "collection_items", ["collection_id", "item_id"], name: "index_collection_items_on_collection_id_and_item_id", unique: true, using: :btree

  create_table "collection_ownerships", force: :cascade do |t|
    t.string   "api_id",        limit: 12, null: false
    t.integer  "collection_id",            null: false
    t.integer  "ownership_id",             null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "collection_ownerships", ["api_id"], name: "index_collection_ownerships_on_api_id", unique: true, using: :btree
  add_index "collection_ownerships", ["collection_id", "ownership_id"], name: "index_collection_ownerships_on_collection_id_and_ownership_id", unique: true, using: :btree

  create_table "collection_works", force: :cascade do |t|
    t.string   "api_id",        limit: 12, null: false
    t.integer  "collection_id",            null: false
    t.integer  "work_id",                  null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "collection_works", ["api_id"], name: "index_collection_works_on_api_id", unique: true, using: :btree
  add_index "collection_works", ["collection_id", "work_id"], name: "index_collection_works_on_collection_id_and_work_id", unique: true, using: :btree

  create_table "collections", force: :cascade do |t|
    t.string   "api_id",                  limit: 12,                 null: false
    t.string   "name",                    limit: 50,                 null: false
    t.string   "normalized_name",         limit: 50,                 null: false
    t.string   "display_name",            limit: 50,                 null: false
    t.boolean  "public_access",                      default: false, null: false
    t.boolean  "featured",                           default: false, null: false
    t.json     "data",                                               null: false
    t.integer  "linked_works_count",                 default: 0,     null: false
    t.integer  "linked_items_count",                 default: 0,     null: false
    t.integer  "linked_ownerships_count",            default: 0,     null: false
    t.integer  "user_id",                                            null: false
    t.integer  "creator_id",                                         null: false
    t.integer  "updater_id",                                         null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
  end

  add_index "collections", ["api_id"], name: "index_collections_on_api_id", unique: true, using: :btree
  add_index "collections", ["normalized_name", "user_id"], name: "index_collections_on_normalized_name_and_user_id", unique: true, using: :btree

  create_table "collections_users", id: false, force: :cascade do |t|
    t.integer "collection_id", null: false
    t.integer "user_id",       null: false
  end

  add_index "collections_users", ["collection_id", "user_id"], name: "index_collections_users_on_collection_id_and_user_id", unique: true, using: :btree

  create_table "companies", force: :cascade do |t|
    t.string   "api_id",     limit: 12,  null: false
    t.string   "name",       limit: 100, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "creator_id",             null: false
    t.integer  "updater_id",             null: false
  end

  add_index "companies", ["api_id"], name: "index_companies_on_api_id", unique: true, using: :btree
  add_index "companies", ["name"], name: "index_companies_on_name", unique: true, using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "api_id",           limit: 36, null: false
    t.integer  "api_version",                 null: false
    t.string   "event_type",       limit: 12, null: false
    t.string   "event_subject",    limit: 50
    t.string   "trackable_type",   limit: 50
    t.integer  "trackable_id"
    t.json     "previous_version"
    t.integer  "cause_id"
    t.integer  "user_id"
    t.datetime "created_at",                  null: false
    t.string   "trackable_api_id", limit: 12, null: false
  end

  add_index "events", ["trackable_type", "trackable_api_id"], name: "index_events_on_trackable_type_and_trackable_api_id", using: :btree
  add_index "events", ["trackable_type", "trackable_id"], name: "index_events_on_trackable_type_and_trackable_id", using: :btree

  create_table "image_searches", force: :cascade do |t|
    t.string   "api_id",         limit: 12,  null: false
    t.integer  "imageable_id"
    t.string   "imageable_type", limit: 25
    t.string   "engine",         limit: 25,  null: false
    t.string   "query",          limit: 255, null: false
    t.json     "results",                    null: false
    t.integer  "results_count",              null: false
    t.integer  "user_id",                    null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "images", force: :cascade do |t|
    t.string   "api_id",                 limit: 12,  null: false
    t.string   "url",                    limit: 255, null: false
    t.string   "content_type",           limit: 50
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
    t.string   "state",                  limit: 20,  null: false
    t.string   "original_url",           limit: 255
    t.string   "original_thumbnail_url", limit: 255
    t.text     "upload_error"
    t.datetime "uploading_at"
    t.datetime "uploaded_at"
  end

  create_table "items", force: :cascade do |t|
    t.string   "api_id",                          limit: 12,  null: false
    t.string   "type",                            limit: 6,   null: false
    t.integer  "work_id",                                     null: false
    t.integer  "title_id"
    t.integer  "image_id"
    t.string   "custom_title",                    limit: 150
    t.integer  "custom_title_language_id"
    t.integer  "range_start"
    t.integer  "range_end"
    t.integer  "language_id",                                 null: false
    t.string   "edition",                         limit: 25
    t.integer  "version"
    t.string   "format",                          limit: 25
    t.integer  "length"
    t.json     "properties"
    t.string   "publisher",                       limit: 50
    t.string   "isbn",                            limit: 13
    t.integer  "creator_id",                                  null: false
    t.integer  "updater_id",                                  null: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.date     "release_date"
    t.date     "original_release_date",                       null: false
    t.string   "release_date_precision",          limit: 1
    t.string   "original_release_date_precision", limit: 1
    t.text     "sortable_title",                              null: false
    t.integer  "last_image_search_id"
    t.string   "issn",                            limit: 8
    t.integer  "scrap_id"
    t.integer  "media_url_id"
  end

  add_index "items", ["api_id"], name: "index_items_on_api_id", unique: true, using: :btree
  add_index "items", ["isbn"], name: "index_items_on_isbn", unique: true, using: :btree

  create_table "items_audio_languages", id: false, force: :cascade do |t|
    t.integer "video_id",    null: false
    t.integer "language_id", null: false
  end

  add_index "items_audio_languages", ["video_id", "language_id"], name: "index_audio_languages_on_video_id_and_language_id", unique: true, using: :btree

  create_table "items_subtitle_languages", id: false, force: :cascade do |t|
    t.integer "video_id",    null: false
    t.integer "language_id", null: false
  end

  add_index "items_subtitle_languages", ["video_id", "language_id"], name: "index_subtitle_languages_on_video_id_and_language_id", unique: true, using: :btree

  create_table "languages", force: :cascade do |t|
    t.string "tag", limit: 5, null: false
  end

  add_index "languages", ["tag"], name: "index_languages_on_tag", unique: true, using: :btree

  create_table "media_files", force: :cascade do |t|
    t.string   "type",             limit: 14,                 null: false
    t.string   "api_id",           limit: 12,                 null: false
    t.text     "path",                                        null: false
    t.boolean  "deleted",                     default: false, null: false
    t.integer  "source_id",                                   null: false
    t.integer  "directory_id"
    t.integer  "depth",                       default: 0,     null: false
    t.integer  "bytesize",         limit: 8
    t.integer  "files_count",                 default: 0,     null: false
    t.datetime "scanned_at"
    t.integer  "last_scan_id"
    t.datetime "file_created_at"
    t.datetime "file_modified_at"
    t.datetime "deleted_at"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.json     "properties"
    t.string   "state",            limit: 20
    t.string   "extension",        limit: 20
    t.integer  "media_url_id"
  end

  add_index "media_files", ["api_id"], name: "index_media_files_on_api_id", unique: true, using: :btree
  add_index "media_files", ["path", "source_id"], name: "index_media_files_on_path_and_source_id", unique: true, using: :btree

  create_table "media_scan_files", force: :cascade do |t|
    t.integer "scan_id",                                null: false
    t.text    "path",                                   null: false
    t.json    "data",                                   null: false
    t.boolean "processed",              default: false, null: false
    t.string  "change_type", limit: 10,                 null: false
  end

  add_index "media_scan_files", ["path", "scan_id"], name: "index_media_scan_files_on_path_and_scan_id", unique: true, using: :btree

  create_table "media_scanners", force: :cascade do |t|
    t.string   "api_id",       limit: 36, null: false
    t.datetime "scanned_at"
    t.integer  "last_scan_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.json     "properties"
    t.integer  "user_id",                 null: false
  end

  add_index "media_scanners", ["api_id"], name: "index_media_scanners_on_api_id", unique: true, using: :btree

  create_table "media_scans", force: :cascade do |t|
    t.string   "api_id",                limit: 12,             null: false
    t.integer  "scanner_id",                                   null: false
    t.integer  "files_count",                      default: 0, null: false
    t.integer  "processed_files_count",            default: 0, null: false
    t.json     "properties"
    t.datetime "created_at"
    t.datetime "processed_at"
    t.integer  "source_id",                                    null: false
    t.string   "state",                 limit: 10,             null: false
    t.datetime "canceled_at"
    t.datetime "scanned_at"
    t.datetime "failed_at"
    t.text     "error_backtrace"
    t.integer  "changed_files_count",              default: 0, null: false
    t.string   "error_message"
  end

  add_index "media_scans", ["api_id"], name: "index_media_scans_on_api_id", unique: true, using: :btree

  create_table "media_sources", force: :cascade do |t|
    t.string   "api_id",          limit: 12,             null: false
    t.string   "name",            limit: 50,             null: false
    t.string   "normalized_name", limit: 50,             null: false
    t.integer  "files_count",                default: 0, null: false
    t.integer  "scans_count",                default: 0, null: false
    t.datetime "scanned_at"
    t.integer  "last_scan_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.json     "data"
    t.json     "properties"
    t.integer  "user_id",                                null: false
  end

  add_index "media_sources", ["api_id"], name: "index_media_sources_on_api_id", unique: true, using: :btree
  add_index "media_sources", ["normalized_name", "user_id"], name: "index_media_sources_on_normalized_name_and_user_id", unique: true, using: :btree

  create_table "media_urls", force: :cascade do |t|
    t.string   "api_id",      limit: 12,  null: false
    t.string   "provider",    limit: 20,  null: false
    t.string   "category",    limit: 20,  null: false
    t.string   "provider_id", limit: 100, null: false
    t.integer  "creator_id",              null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "media_urls", ["provider", "provider_id"], name: "index_media_urls_on_provider_and_provider_id", unique: true, using: :btree

  create_table "ownerships", force: :cascade do |t|
    t.string   "api_id",     limit: 12,                null: false
    t.integer  "item_id",                              null: false
    t.integer  "user_id",                              null: false
    t.json     "properties"
    t.datetime "gotten_at",                            null: false
    t.integer  "creator_id",                           null: false
    t.integer  "updater_id",                           null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "owned",                 default: true, null: false
    t.datetime "yielded_at"
  end

  create_table "people", force: :cascade do |t|
    t.string   "api_id",      limit: 12,  null: false
    t.string   "last_name",   limit: 50
    t.string   "first_names", limit: 100
    t.string   "pseudonym",   limit: 50
    t.integer  "creator_id",              null: false
    t.integer  "updater_id",              null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "scraps", force: :cascade do |t|
    t.string   "api_id",          limit: 12, null: false
    t.string   "provider",        limit: 20, null: false
    t.string   "state",           limit: 20, null: false
    t.text     "contents"
    t.string   "content_type",    limit: 50
    t.integer  "media_url_id",               null: false
    t.integer  "creator_id",                 null: false
    t.datetime "scraping_at"
    t.datetime "canceled_at"
    t.datetime "scraped_at"
    t.datetime "failed_at"
    t.text     "error_message"
    t.text     "error_backtrace"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "scraps", ["api_id"], name: "index_scraps_on_api_id", unique: true, using: :btree
  add_index "scraps", ["media_url_id"], name: "index_scraps_on_media_url_id", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "api_id",          limit: 12,                  null: false
    t.string   "email",           limit: 255,                 null: false
    t.integer  "sign_in_count",               default: 0,     null: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "name",            limit: 25,                  null: false
    t.string   "normalized_name", limit: 25,                  null: false
    t.boolean  "active",                      default: false, null: false
    t.integer  "roles_mask",                  default: 0,     null: false
    t.datetime "active_at"
  end

  add_index "users", ["api_id"], name: "index_users_on_api_id", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["normalized_name"], name: "index_users_on_normalized_name", unique: true, using: :btree

  create_table "work_companies", force: :cascade do |t|
    t.integer "company_id",             null: false
    t.integer "work_id",                null: false
    t.string  "relation",   limit: 20,  null: false
    t.string  "details",    limit: 255
  end

  add_index "work_companies", ["work_id", "company_id"], name: "index_work_companies_on_work_id_and_company_id", unique: true, using: :btree

  create_table "work_descriptions", force: :cascade do |t|
    t.string  "api_id",      limit: 12, null: false
    t.integer "work_id",                null: false
    t.integer "language_id",            null: false
    t.text    "contents",               null: false
  end

  add_index "work_descriptions", ["api_id"], name: "index_work_descriptions_on_api_id", unique: true, using: :btree

  create_table "work_links", force: :cascade do |t|
    t.string  "url",         limit: 255, null: false
    t.integer "work_id",                 null: false
    t.integer "language_id"
  end

  add_index "work_links", ["work_id", "url"], name: "index_work_links_on_work_id_and_url", unique: true, using: :btree

  create_table "work_people", force: :cascade do |t|
    t.integer "work_id",               null: false
    t.integer "person_id",             null: false
    t.string  "relation",  limit: 20,  null: false
    t.string  "details",   limit: 255
  end

  add_index "work_people", ["work_id", "person_id"], name: "index_work_people_on_work_id_and_person_id", unique: true, using: :btree

  create_table "work_titles", force: :cascade do |t|
    t.string  "api_id",           limit: 12,  null: false
    t.integer "work_id",                      null: false
    t.integer "language_id",                  null: false
    t.string  "contents",         limit: 150, null: false
    t.integer "display_position",             null: false
  end

  add_index "work_titles", ["api_id"], name: "index_work_titles_on_api_id", unique: true, using: :btree

  create_table "works", force: :cascade do |t|
    t.string   "api_id",               limit: 6,  null: false
    t.string   "category",             limit: 10, null: false
    t.integer  "number_of_items"
    t.integer  "original_title_id"
    t.integer  "start_year"
    t.integer  "end_year"
    t.integer  "language_id",                     null: false
    t.integer  "image_id"
    t.json     "properties"
    t.integer  "creator_id",                      null: false
    t.integer  "updater_id",                      null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "last_image_search_id"
    t.integer  "scrap_id"
    t.integer  "media_url_id"
  end

  add_index "works", ["api_id"], name: "index_works_on_api_id", unique: true, using: :btree
  add_index "works", ["category"], name: "index_works_on_category", using: :btree
  add_index "works", ["media_url_id"], name: "index_works_on_media_url_id", unique: true, using: :btree

  add_foreign_key "collection_items", "collections", on_delete: :cascade
  add_foreign_key "collection_items", "items", on_delete: :cascade
  add_foreign_key "collection_ownerships", "collections", on_delete: :cascade
  add_foreign_key "collection_ownerships", "ownerships", on_delete: :cascade
  add_foreign_key "collection_works", "collections", on_delete: :cascade
  add_foreign_key "collection_works", "works", on_delete: :cascade
  add_foreign_key "collections", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "collections", "users", column: "updater_id", on_delete: :restrict
  add_foreign_key "collections", "users", on_delete: :restrict
  add_foreign_key "collections_users", "collections", on_delete: :cascade
  add_foreign_key "collections_users", "users", on_delete: :restrict
  add_foreign_key "companies", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "companies", "users", column: "updater_id", on_delete: :restrict
  add_foreign_key "events", "events", column: "cause_id", on_delete: :cascade
  add_foreign_key "events", "users", on_delete: :restrict
  add_foreign_key "image_searches", "users", on_delete: :restrict
  add_foreign_key "items", "image_searches", column: "last_image_search_id", on_delete: :nullify
  add_foreign_key "items", "images", on_delete: :nullify
  add_foreign_key "items", "languages", column: "custom_title_language_id", on_delete: :restrict
  add_foreign_key "items", "languages", on_delete: :restrict
  add_foreign_key "items", "media_urls", on_delete: :nullify
  add_foreign_key "items", "scraps", on_delete: :nullify
  add_foreign_key "items", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "items", "users", column: "updater_id", on_delete: :restrict
  add_foreign_key "items", "work_titles", column: "title_id", on_delete: :nullify
  add_foreign_key "items", "works", on_delete: :cascade
  add_foreign_key "items_audio_languages", "items", column: "video_id", on_delete: :cascade
  add_foreign_key "items_audio_languages", "languages", on_delete: :restrict
  add_foreign_key "items_subtitle_languages", "items", column: "video_id", on_delete: :cascade
  add_foreign_key "items_subtitle_languages", "languages", on_delete: :restrict
  add_foreign_key "media_files", "media_files", column: "directory_id", on_delete: :cascade
  add_foreign_key "media_files", "media_scans", column: "last_scan_id", on_delete: :nullify
  add_foreign_key "media_files", "media_sources", column: "source_id", on_delete: :cascade
  add_foreign_key "media_files", "media_urls", on_delete: :nullify
  add_foreign_key "media_scan_files", "media_scans", column: "scan_id", on_delete: :cascade
  add_foreign_key "media_scanners", "media_scans", column: "last_scan_id", on_delete: :nullify
  add_foreign_key "media_scanners", "users", on_delete: :cascade
  add_foreign_key "media_scans", "media_scanners", column: "scanner_id", on_delete: :cascade
  add_foreign_key "media_scans", "media_sources", column: "source_id", on_delete: :cascade
  add_foreign_key "media_sources", "media_scans", column: "last_scan_id", on_delete: :nullify
  add_foreign_key "media_sources", "users", on_delete: :cascade
  add_foreign_key "media_urls", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "ownerships", "items", on_delete: :cascade
  add_foreign_key "ownerships", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "ownerships", "users", column: "updater_id", on_delete: :restrict
  add_foreign_key "ownerships", "users", on_delete: :restrict
  add_foreign_key "people", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "people", "users", column: "updater_id", on_delete: :restrict
  add_foreign_key "scraps", "media_urls", on_delete: :cascade
  add_foreign_key "scraps", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "work_companies", "companies", on_delete: :cascade
  add_foreign_key "work_companies", "works", on_delete: :cascade
  add_foreign_key "work_descriptions", "languages", on_delete: :restrict
  add_foreign_key "work_descriptions", "works", on_delete: :cascade
  add_foreign_key "work_links", "languages", on_delete: :restrict
  add_foreign_key "work_links", "works", on_delete: :cascade
  add_foreign_key "work_people", "people", on_delete: :restrict
  add_foreign_key "work_people", "works", on_delete: :cascade
  add_foreign_key "work_titles", "languages", on_delete: :restrict
  add_foreign_key "work_titles", "works"
  add_foreign_key "works", "image_searches", column: "last_image_search_id", on_delete: :nullify
  add_foreign_key "works", "images", on_delete: :nullify
  add_foreign_key "works", "languages", on_delete: :restrict
  add_foreign_key "works", "media_urls", on_delete: :nullify
  add_foreign_key "works", "scraps", on_delete: :nullify
  add_foreign_key "works", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "works", "users", column: "updater_id", on_delete: :restrict
  add_foreign_key "works", "work_titles", column: "original_title_id", on_delete: :nullify
end
