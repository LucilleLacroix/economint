class Reconciliation < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  validates :name, presence: true
  attr_accessor :start_date, :end_date
end
