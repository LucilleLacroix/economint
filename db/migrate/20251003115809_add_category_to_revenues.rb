class AddCategoryToRevenues < ActiveRecord::Migration[7.1]
  def change
    # Étape 1 : on ajoute la colonne, mais autorise null temporairement
    add_reference :revenues, :category, foreign_key: true, null: true

    # Étape 2 : pour éviter les NULL sur les anciennes lignes,
    # on met toutes les anciennes revenues dans une catégorie "Autres" ou "Revenus".
    reversible do |dir|
      dir.up do
        # Crée une catégorie par défaut pour chaque user (si tu veux une par user)
        User.find_each do |user|
          default_category = user.categories.find_or_create_by!(name: "Revenus", color: "#2ecc71")
          user.revenues.update_all(category_id: default_category.id)
        end
      end
    end

    # Étape 3 : on applique la contrainte NOT NULL maintenant que tout est rempli
    change_column_null :revenues, :category_id, false
  end
end
