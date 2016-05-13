require 'rails_helper'

RSpec.describe Volume, type: :model do
  describe "ISBN" do
    let(:creator){ create :user }
    let(:language){ create :language, tag: :en }
    let(:work){ create :work, category: 'book', language: language, start_year: 2000, end_year: 2001, creator: creator }

    it "should be normalized if it is an ISBN-13" do
      volume = create :volume, work: work, isbn: '978-3-16-148410-0'
      expect(volume.isbn).to eq('9783161484100')
    end

    it "should be normalized if it is an ISBN-10" do
      volume = create :volume, work: work, isbn: '0-8044-2957-X'
      expect(volume.isbn).to eq('080442957X')
    end
  end
end
