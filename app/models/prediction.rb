class Prediction < ApplicationRecord
  belongs_to :user

  # Validation simple
  validates :scenario_name, presence: true
  has_many :predictions, dependent: :destroy
  validates :predicted_value, presence: true, numericality: true
  validates :predicted_at, presence: true

end
