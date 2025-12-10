class Reconciliation < ApplicationRecord
  belongs_to :user

  # Trie automatiquement les transactions par date puis par id
  has_many :transactions, -> { order(date: :asc, id: :asc) }, dependent: :destroy

  validates :name, presence: true
end
