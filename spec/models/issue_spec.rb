require 'rails_helper'

RSpec.describe Issue, type: :model do
  describe "ISSN" do
    let(:creator){ create :user }
    let(:language){ create :language, tag: :en }
    let(:work){ create :work, category: 'magazine', language: language, start_year: 2000, end_year: 2001, creator: creator }

    it "should be normalized" do
      volume = create :issue, work: work, issn: '0028-0836'
      expect(volume.issn).to eq('00280836')
    end
  end
end
