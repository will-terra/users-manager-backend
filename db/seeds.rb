# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed users for the application
# Using find_or_initialize_by to make this idempotent - safe to run multiple times

puts "Seeding users..."

# Admin user
admin = User.find_or_initialize_by(email: "admin@example.com") do |user|
  user.full_name = "Admin User"
  user.role = "admin"
  user.password = "password123"
  user.password_confirmation = "password123"
end

if admin.new_record?
  admin.save!
  puts "✓ Created admin user: #{admin.email}"
else
  puts "- Admin user already exists: #{admin.email}"
end

# Regular test user
test_user = User.find_or_initialize_by(email: "teste@teste.com") do |user|
  user.full_name = "Test User"
  user.role = "user"
  user.password = "123456"
  user.password_confirmation = "123456"
end

if test_user.new_record?
  test_user.save!
  puts "✓ Created test user: #{test_user.email}"
else
  puts "- Test user already exists: #{test_user.email}"
end

# Additional sample users
sample_users = [
  { email: "john.doe@example.com", full_name: "John Doe", role: "user" },
  { email: "jane.smith@example.com", full_name: "Jane Smith", role: "user" },
  { email: "alice.johnson@example.com", full_name: "Alice Johnson", role: "admin" }
]

sample_users.each do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email]) do |u|
    u.full_name = user_data[:full_name]
    u.role = user_data[:role]
    u.password = "password123"
    u.password_confirmation = "password123"
  end

  if user.new_record?
    user.save!
    puts "✓ Created #{user.role} user: #{user.email}"
  else
    puts "- User already exists: #{user.email}"
  end
end

puts "\nSeeding completed!"
puts "Total users in database: #{User.count}"
puts "Admin users: #{User.admins.count}"
puts "Regular users: #{User.users.count}"
