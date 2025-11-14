FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'user' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
