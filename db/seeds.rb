# db/seeds.rb

puts "Cleaning database..."
Transaction.delete_all
Reconciliation.delete_all
Prediction.delete_all
Goal.delete_all
Expense.delete_all
ChecklistItem.delete_all
Checklist.delete_all
Category.delete_all
User.delete_all

puts "Creating users..."
user1 = User.create!(
  email: "alice@example.com",
  password: "password",
  password_confirmation: "password",
  username: "alice"
)

user2 = User.create!(
  email: "bob@example.com",
  password: "password",
  password_confirmation: "password",
  username: "bob"
)
User.all.each do |user|
  Revenue.create!(
    user: user,
    amount: 3000.0,
    category: "Salaire",
    description: "Revenu mensuel fixe",
    date: Date.today.beginning_of_month
  )
end
puts "Creating categories..."
food = Category.create!(user: user1, name: "Food")
transport = Category.create!(user: user1, name: "Transport")
entertainment = Category.create!(user: user2, name: "Entertainment")
bills = Category.create!(user: user2, name: "Bills")
health = Category.create!(user: user2, name: "Health")

puts "Creating checklists and checklist items..."
checklist1 = Checklist.create!(user: user1, title: "Daily Tasks")
ChecklistItem.create!(checklist: checklist1, content: "Check emails", done: true)
ChecklistItem.create!(checklist: checklist1, content: "Morning workout", done: false)

checklist2 = Checklist.create!(user: user2, title: "Weekend Plans")
ChecklistItem.create!(checklist: checklist2, content: "Buy groceries", done: false)
ChecklistItem.create!(checklist: checklist2, content: "Go to cinema", done: true)

puts "Creating expenses..."
expense1 = Expense.create!(user: user1, category: food, amount: 25.50, description: "Lunch at cafe", date: Date.today - 5)
expense2 = Expense.create!(user: user1, category: transport, amount: 15.00, description: "Bus ticket", date: Date.today - 3)
expense3 = Expense.create!(user: user2, category: entertainment, amount: 50.00, description: "Movie night", date: Date.today - 2)
expense4 = Expense.create!(user: user2, category: bills, amount: 120.00, description: "Electricity bill", date: Date.today - 7)
puts "Seeds finished!"
puts "Users: #{User.count}, Categories: #{Category.count}, Checklists: #{Checklist.count}, Checklist items: #{ChecklistItem.count}, Expenses: #{Expense.count}, Goals: #{Goal.count}, Predictions: #{Prediction.count}, Reconciliations: #{Reconciliation.count}, Transactions: #{Transaction.count}"
