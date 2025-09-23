class CreateChecklistItems < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_items do |t|
      t.references :checklist, null: false, foreign_key: true
      t.string :content
      t.boolean :done

      t.timestamps
    end
  end
end
