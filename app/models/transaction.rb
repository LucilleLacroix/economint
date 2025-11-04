class Transaction < ApplicationRecord
  belongs_to :reconciliation
  belongs_to :matchable, polymorphic: true, optional: true
end
