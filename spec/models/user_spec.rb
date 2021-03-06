require 'rails_helper'

RSpec.describe User, :type => :model do
  let(:user){ create :user }

  it "should set a random identifier when created" do
    user2 = create(:user)
    expect(user.api_id).to match(/\A[a-z0-9]{12}\Z/)
    expect(user2.api_id).to match(/\A[a-z0-9]{12}\Z/)
    expect(user.api_id).not_to eq(user2.api_id)
  end

  describe "validations" do
    it{ should validate_presence_of(:email) }
    it{ should validate_length_of(:email).is_at_most(255) }

    describe "with an existing user" do
      before(:each){ create :user }
      it{ should validate_uniqueness_of(:email).case_insensitive }
    end
  end

  describe "database table" do
    it{ should have_db_column(:id).of_type(:integer).with_options(null: false) }
    it{ should have_db_column(:api_id).of_type(:string).with_options(null: false, limit: 12) }
    it{ should have_db_column(:name).of_type(:string).with_options(null: false, limit: 25) }
    it{ should have_db_column(:normalized_name).of_type(:string).with_options(null: false, limit: 25) }
    it{ should have_db_column(:email).of_type(:string).with_options(null: false, limit: 255) }
    it{ should have_db_column(:active).of_type(:boolean).with_options(null: false, default: false) }
    it{ should have_db_column(:roles_mask).of_type(:integer).with_options(null: false, default: 0) }
    it{ should have_db_column(:sign_in_count).of_type(:integer).with_options(null: false, default: 0) }
    it{ should have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it{ should have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
    it{ should have_db_columns(:id, :api_id, :name, :normalized_name, :email, :active, :roles_mask, :sign_in_count, :created_at, :updated_at) }
  end
end
