get 'projects/:project_id/calendar_subscription', :to => 'calendar_subscription#show', :as => 'project_calendar_subscription'
get 'calendar_subscription', :to => 'calendar_subscription#show'
get 'calendar_subscription/admin/users', :to => 'calendar_subscription_admin#users', :defaults => { :format => 'json' }
