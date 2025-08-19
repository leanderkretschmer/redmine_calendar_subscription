class AddDueTimeToIssues < ActiveRecord::Migration[7.0]
  def change
    change_column :issues, :due_date, :datetime
  end
end
