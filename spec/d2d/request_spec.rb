RSpec.describe D2D::Client::Request do
  include described_class

  context 'RequestItem' do
    it 'executes constructor with title search' do
      options ={ title: 'hey you', pickup_location: 'DHHILL' }
      req = D2D::Client::RequestItem.new(options)
      expect(req.body[:BibSearch]).not_to be_nil
      expect(req.body[:BibSearch][:Title]).to eq(options[:title])
      expect(req.body[:ExactSearch]).to be_nil
    end

    it 'executes constructor with isbn' do
      options = { isbn: '978123456789X', pickup_location: 'HUNT' }
      req = D2D::Client::RequestItem.new(options)
      bib = req.body[:BibSearch]
      exact = req.body[:ExactSearch]
      expect(bib).to be_nil
      expect(exact).not_to be_nil
      expect(exact).to be_a(Array)
      expect(exact.first[:Type]).to eq('ISBN')
      expect(exact.first[:Value]).to eq(options[:isbn])
    end
  end
end
