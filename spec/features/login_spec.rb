require 'rails_helper'

RSpec.describe "login" do
  let(:user){ create :user }

  it "should allow the user to sign in" do

    visit '/'
    expect(page).to have_content('Lair')

    click_link 'Sign in'
    expect(page).to have_content('Sign in with Google')

    token = auth_token user

    within '.loginDialog' do
      fill_in 'credentials', with: token
      click_button 'Test'
    end

    expect(page).to have_content(user.email)
  end
end
