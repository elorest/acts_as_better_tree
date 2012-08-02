FactoryGirl.define do
    factory :animals, class: Category do
      name "animals"
    end

    factory :cats, class: Category do
      name "cats"
      association :parent, factory: :animals, strategy: :build
    end
end