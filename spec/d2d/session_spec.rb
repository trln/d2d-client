describe D2D::Client::Session do
  include D2D::Client
  before do
    D2D::Client.configure do |config|
      config.library_symbol = 'TRLN'
      config.partnership_id = 'TRLN'
      config.base_url = 'http://localhost:1231/api'
      config.api_key = 'richard moranis'
      config.patron_id = '123456789'
    end
  end

  let(:request_item_response) do
    {
      request_number: '123456789',
      button_link: 'https://trln.org/d2d-sample',
      button_label: 'look a request button',
      request_message: 'look a request message'
    }
  end

  let(:request_item_session) do
    content = Helpers.hash_fill!(
      load_json('request_item_response'),
      request_item_response
    )
    fake_response = Helpers::MockResponse.new(content)
    D2D::Client::Session.new(nil, client: Helpers::MockClient.new(fake_response))
  end

  context 'request_item' do
    it 'populates the AddItem body correctly' do
      resp = request_item_session.request_item(title: 'Hey you', note: 'volume 1 please')
      expect(resp).to be_a(D2D::Client::RequestItemResponse)
      expect(resp.request_number).to eq(request_item_response[:request_number])
    end
  end
end
