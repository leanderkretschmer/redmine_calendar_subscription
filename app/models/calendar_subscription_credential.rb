class CalendarSubscriptionCredential < ActiveRecord::Base
  self.table_name = 'calendar_subscription_credentials'

  has_secure_password validations: false

  belongs_to :user

  validates :user_id, presence: true
  validates :username, presence: true, unless: :use_redmine_credentials?
end


