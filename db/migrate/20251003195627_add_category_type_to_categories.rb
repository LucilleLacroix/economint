class AddCategoryTypeToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :category_type, :string, default: "expense", null: false
    add_index :categories, :category_type
  end
end
