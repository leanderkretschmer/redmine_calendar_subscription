Time::DATE_FORMATS[:ical] = "%Y%m%dT%H%M00Z"

class CalendarSubscriptionController < ApplicationController

  before_action :find_optional_project
  

  include QueriesHelper
  include SortHelper

  def show
    unless allowed_to_subscribe?(User.current)
      render plain: 'Forbidden', status: :forbidden and return
    end
    start_date = Date.today - Setting.plugin_redmine_calendar_subscription[:past_days].to_i.days
    end_date = Date.today + Setting.plugin_redmine_calendar_subscription[:future_days].to_i.days
    limit = Setting.plugin_redmine_calendar_subscription[:maximum_issues].to_i

    retrieve_query
    @query.group_by = nil

    calendar = Icalendar::Calendar.new
    #calendar.publish

    if @query.valid?
      issues = @query.issues(:include => [:tracker, :author, :assigned_to, :priority, :fixed_version],
                             :conditions => Issue.arel_table[:due_date].in(start_date..end_date).and(Issue.arel_table[Issue.left_column_name].eq(Issue.arel_table[Issue.right_column_name] - 1)),
                             :limit => limit, :offset => 0)
      issues.each do |issue|
        next unless issue.due_date && issue.estimated_hours
        calendar.add_event issue_to_event(issue)
      end
      #@events += @query.versions(:conditions => { :effective_date => [start_date, end_date] })
    end

    render plain: calendar.to_ical, content_type: 'text/calendar'
  end

  private

  def issue_to_event(issue)
    event = Icalendar::Event.new
    start_time = (issue.due_date - issue.estimated_hours.hours)
    end_time = issue.due_date
    event.dtstart = Icalendar::Values::DateTime.new(start_time.utc)
    event.dtend = Icalendar::Values::DateTime.new(end_time.utc)
    event.uid = issue_url(issue, plugin: 'redmine_calendar_subscription')
    event.url = issue_url(issue)
    event.summary = "[#{issue.project.name}] #{issue.tracker.name}: #{issue.subject} (##{issue.id})"
    event.description = issue.description unless issue.description.blank?
    event.priority = ics_priority issue.priority
    event.sequence = issue.lock_version
    category = issue.fixed_version.nil? ? issue.project.name : "#{issue.project.name} - #{issue.fixed_version.name}"
    event.append_custom_property('CATEGORIES', category)
    event.created = Icalendar::Values::DateTime.new(issue.created_on.utc)
    event.last_modified = Icalendar::Values::DateTime.new(issue.updated_on.utc) unless issue.updated_on.nil?
    event.transp = 'TRANSPARENT'
    event
  end

  def ics_priority(priority)
    ics_priority_map[priority.position]
  end

  def ics_priority_map
    # [position] => ICS-Priority (1 - highest, 9 - lowest)
    @priority_map ||=
        begin
          priorities = IssuePriority.where(:active => true).all.sort_by(&:position)
          max = priorities.size-1
          map = {}
          if priorities.any?
            default = priorities.index(&:is_default?) || ((priorities.size - 1) / 2)
            priorities.each_with_index do |priority, index|
              map[priority.position] = case index
                                         when 0
                                           9
                                         when 1..default-1
                                           8-(3.0/(default-1)*(index-1)).floor
                                         when default
                                           5
                                         when default+1..max-1
                                           4-(3.0/(max - default - 2)*(1 + index - default)).floor
                                         when max
                                           1
                                         else
                                           1
                                       end
            end
          end
          map
        end
  end

  def allowed_to_subscribe?(user)
    settings = Setting.plugin_redmine_calendar_subscription || {}
    allowed_ids = Array(settings[:allowed_user_ids]).map(&:to_i)
    return true if allowed_ids.empty?
    allowed_ids.include?(user.id)
  end
end
