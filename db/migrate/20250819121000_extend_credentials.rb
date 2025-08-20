class ExtendCredentials < ActiveRecord::Migration[7.0]
  def change
    add_column :calendar_subscription_credentials, :mode, :string, null: false, default: 'redmine' # redmine|custom|none
    add_column :calendar_subscription_credentials, :expires_at, :datetime
    add_column :calendar_subscription_credentials, :paused, :boolean, null: false, default: false
    add_index  :calendar_subscription_credentials, :mode
  end
end


