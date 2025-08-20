class CalendarSubscriptionCredential < ActiveRecord::Base
  self.table_name = 'calendar_subscription_credentials'

  has_secure_password validations: false

  belongs_to :user

  validates :user_id, presence: true
  validates :username, presence: true, if: :custom_mode?

  enum_mode = %w[redmine custom none]

  def custom_mode?
    (mode || 'redmine') == 'custom'
  end

  def use_redmine_credentials
    (mode || 'redmine') == 'redmine'
  end

  def use_redmine_credentials=(flag)
    self.mode = ActiveModel::Type::Boolean.new.cast(flag) ? 'redmine' : (mode == 'redmine' ? 'custom' : mode)
  end
end


