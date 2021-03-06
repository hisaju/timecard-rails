class Workload < ActiveRecord::Base
  include PublicActivity::Model

  default_scope { order("updated_at DESC") }

  scope :complete, -> { where("end_at is not ?", nil) }
  scope :uncomplete, -> { where("end_at IS NULL") }
  scope :daily, ->(now = Time.zone.now) do
    where("start_at >= ? AND start_at < ?", now.beginning_of_day, now.end_of_day) 
  end
  scope :weekly, ->(now = Time.zone.now) do
    where("start_at >= ? AND start_at <= ?", now.beginning_of_week, now.end_of_week)
  end

  belongs_to :issue
  belongs_to :user

  validates :start_at, presence: true

  after_create :track_start_activity
  before_update :track_stop_activity

  def self.running?
    exists?(["start_at is not ? and end_at is ?", nil, nil])
  end

  def duration
    end_at_or_now - start_at
  end

  def self.total_duration
    complete.inject(0) {|sum, w| sum += w.duration }
  end

  def self.formatted_total_duration
    duration = self.total_duration
    hour = (duration / (60 * 60)).floor
    duration = duration - (hour * 60 * 60)
    min = (duration / 60).floor
    sec = duration - (min * 60)
    "#{sprintf('%02d', hour)}:#{sprintf('%02d', min)}:#{sprintf('%02d', sec)}"
  end

  def formatted_duration(format = '%h:%m:%s')
    Time.diff(start_at, end_at_or_now, format)[:diff]
  end

  def formatted_distance_of_time
    started_at = "#{sprintf('%02d', start_at.hour)}:#{sprintf('%02d', start_at.min)}"
    stopped_at = "#{sprintf('%02d', end_at.hour)}:#{sprintf('%02d', end_at.min)}"
    "#{started_at}-#{stopped_at}"
  end

  def stop
    update!(end_at: Time.now)
  end

  private

  def track_start_activity
    self.create_activity(:start, owner: self.user, recipient: self.issue.project)
  end

  def track_stop_activity
    if self.changes.has_key?("end_at") && self.changes["end_at"][0] == nil
      self.create_activity(:stop, owner: self.user, recipient: self.issue.project)
    end
  end

  def end_at_or_now
    (end_at.presence || Time.zone.now)
  end
end
