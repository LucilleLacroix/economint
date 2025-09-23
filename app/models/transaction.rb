class Transaction < ApplicationRecord
  belongs_to :reconciliation
  belongs_to :matched_expense
end
