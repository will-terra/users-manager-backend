FactoryBot.define do
  factory :user_import do
    association :user
    status { 'pending' }
    progress { 0 }
    total_rows { 0 }

    after(:build) do |user_import|
      user_import.file.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'users.csv')),
        filename: 'users.csv',
        content_type: 'text/csv'
      )
    end

    trait :processing do
      status { 'processing' }
      total_rows { 100 }
      progress { 50 }
    end

    trait :completed do
      status { 'completed' }
      total_rows { 100 }
      progress { 100 }
    end

    trait :failed do
      status { 'failed' }
      error_message { 'Import failed due to invalid data' }
    end
  end
end
