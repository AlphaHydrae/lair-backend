class RenameMediaEvents < ActiveRecord::Migration
  class Event < ActiveRecord::Base; end

  def up
    scan_events_rel = Event.where event_type: 'scan'
    say_with_time "renaming #{scan_events_rel.count} scan events to media:scan" do
      scan_events_rel.update_all event_type: 'media:scan'
    end

    scrap_events_rel = Event.where event_type: 'scrap'
    say_with_time "renaming #{scrap_events_rel.count} scrap events to media:scrap" do
      scrap_events_rel.update_all event_type: 'media:scrap'
    end
  end

  def down
    scan_events_rel = Event.where event_type: 'media:scan'
    say_with_time "renaming #{scan_events_rel.count} media:scan events to scan" do
      scan_events_rel.update_all event_type: 'scan'
    end

    scrap_events_rel = Event.where event_type: 'media:scrap'
    say_with_time "renaming #{scrap_events_rel.count} media:scrap events to scrap" do
      scrap_events_rel.update_all event_type: 'scrap'
    end
  end
end
