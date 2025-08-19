# encoding: utf-8

Redmine::Plugin.register :redmine_calendar_subscription do
  name 'Redmine Calendar Subscription'
  author 'Leander Kretschmer'
  description 'Synchronisiere die Kalender-Abos von Redmine mit Allen Clients'
  version '0.4.1'
  url 'https://github.com/leanderkretschmer/redmine_calendar_subscription/tree/master'
  author_url 'https://github.com/leanderkretschmer'
  requires_redmine version_or_higher: '6.0.0'

  settings :default => {
    :past_days => '30',
    :future_days => '90',
    :maximum_issues => '1000',
    :allowed_user_ids => []
  }, :partial => 'settings/calendar_subscription'

  Redmine::AccessControl.map do |map|
    map.project_module :calendar_subscription_plugin do |mod|
      mod.permission :subscribe_calendar, { :calendar_subscription => :show }, :read => true
    end
  end
end

# Ensure plugin lib is on the load path and require main file
$LOAD_PATH.unshift(File.expand_path('lib', __dir__)) unless $LOAD_PATH.include?(File.expand_path('lib', __dir__))
require File.expand_path('lib/redmine_calendar_subscription', __dir__)
