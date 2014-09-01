require 'rails_helper'

RSpec.describe User, :type => :model do

  describe "validations" do
    it{ should validate_presence_of(:email) }

    describe "with an existing user" do
      before(:each){ create :user }

      it{ should validate_uniqueness_of(:email).case_insensitive }
    end
  end

  describe "database table" do
    it{ should have_db_column(:id).of_type(:integer).with_options(null: false) }
    it{ should have_db_column(:email).of_type(:string).with_options(null: false, limit: 255) }
    it{ should have_db_column(:sign_in_count).of_type(:integer).with_options(null: false, default: 0) }
    it{ should have_db_column(:current_sign_in_at).of_type(:datetime).with_options }
    it{ should have_db_column(:last_sign_in_at).of_type(:datetime).with_options }
    it{ should have_db_column(:current_sign_in_ip).of_type(:inet).with_options }
    it{ should have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it{ should have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end
end
