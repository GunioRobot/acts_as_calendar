class Calendar < ActiveRecord::Migration
  def self.up
    create_table :calendars do |t|
    end

    create_table :calendar_dates do |t|
      t.column :value, :date, :null=>false
      t.column :calendar_id, :integer, :null=>false
      t.column :weekday, :integer, :null=>false
      t.column :monthweek, :integer, :null=>false
      t.column :monthday, :integer, :null=>false
      t.column :holiday, :boolean, :null=>false, :default=>false
    end

    create_table :calendar_events do |t|
      t.column :calendar_id, :integer, :null=>false
      t.column :start_date, :date
      t.column :end_date, :date
    end

    create_table :calendar_occurrences do |t|
      t.column :calendar_event_id, :integer, :null=>false
      t.column :calendar_date_id, :integer, :null=>false
    end

    create_table :calendar_recurrences do |t|
      t.column :calendar_event_id, :integer, :null=>false
      t.column :weekday, :integer
      t.column :monthweek, :integer
      t.column :monthday, :integer
    end

    # FIXME - quote embedded holiday parameter
    execute "
      CREATE VIEW calendar_event_dates AS
      SELECT
      ce.id AS calendar_event_id,
      cd.id AS calendar_date_id
      FROM calendar_dates cd
      INNER JOIN calendar_events ce ON cd.holiday = 'f'
        AND (ce.start_date IS NULL OR cd.value >= ce.start_date)
        AND (ce.end_date IS NULL OR cd.value <= ce.end_date)
      LEFT OUTER JOIN calendar_occurrences co
        ON co.calendar_event_id = ce.id
        AND co.calendar_date_id = cd.id
      LEFT OUTER JOIN calendar_recurrences cr ON cr.calendar_event_id = ce.id
        AND ((cr.monthday IS NOT NULL AND cd.monthday = cr.monthday)
          OR (cr.monthday IS NULL AND cr.weekday IS NOT NULL
            AND cd.weekday = cr.weekday
              AND (cr.monthweek IS NULL OR cd.monthweek = cr.monthweek)
          )
        )
      WHERE cr.id IS NOT NULL OR co.id IS NOT NULL
    "
  end

  def self.down
    execute "DROP VIEW calendar_dates_calendar_events"
    drop_table :calendar_recurrences
    drop_table :calendar_occurrences
    drop_table :calendar_events
    drop_table :calendar_dates
    drop_table :calendars
  end
end