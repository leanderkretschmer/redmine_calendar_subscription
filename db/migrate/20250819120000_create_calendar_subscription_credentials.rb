class CreateCalendarSubscriptionCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :calendar_subscription_credentials do |t|
      t.integer :user_id, null: false, index: { unique: true }
      t.string :username
      t.string :password_digest
      t.boolean :use_redmine_credentials, null: false, default: true
      t.timestamps
    end
  end
end


