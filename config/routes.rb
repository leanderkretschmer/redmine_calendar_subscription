get 'projects/:project_id/calendar_subscription', :to => 'calendar_subscription#show', :as => 'project_calendar_subscription'
get 'calendar_subscription', :to => 'calendar_subscription#show'
get 'calendar_subscription/admin/users', :to => 'calendar_subscription_admin#users', :defaults => { :format => 'json' }
get 'calendar_subscription/admin/credentials', :to => 'calendar_subscription_admin#credentials_index', :defaults => { :format => 'json' }
post 'calendar_subscription/admin/credentials', :to => 'calendar_subscription_admin#upsert_credential', :defaults => { :format => 'json' }
delete 'calendar_subscription/admin/credentials/:user_id', :to => 'calendar_subscription_admin#destroy_credential', :as => 'calendar_subscription_admin_credential'
