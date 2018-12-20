require 'logger'

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

  let(:fake_patron) do
    D2D::Client::Patron.new(
      aid: 'not_authorized',
      group: 'patrons',
      library: 'NCSU',
      lang_code: 'Hey',
      first_name: 'Fake',
      last_name: 'Patron',
      type: 'Patron',
      permission: []
    )
  end

  let(:request_item_session) do
    content = Helpers.hash_fill!(
      load_json('request_item_response'),
      request_item_response
    )
    fake_response = Helpers::MockResponse.new(content)
    D2D::Client::Session.new(
      client: Helpers::MockClient.new(fake_response),
      patron: fake_patron
    )
  end

  context 'request_item' do
    it 'populates the AddItem body correctly' do
      expect(request_item_session).not_to be_nil
      resp = request_item_session.request_item(title: 'Hey you', note: 'volume 1 please')
      expect(resp).to be_a(D2D::Client::RequestItemResponse)
      expect(resp.request_number).to eq(request_item_response[:request_number])
    end
  end

  context 'serialization' do
    it 'round trips sessions' do
      orig_hash = request_item_session.to_h
      serialized = request_item_session.to_json
      expect(JSON.parse(serialized)).to eq(orig_hash)
      new_session = described_class.from_json(serialized)
      expect(new_session.to_h).to eq(orig_hash)
    end

    it 'round trips patrons' do
      orig_patron = request_item_session.patron
      serialized = request_item_session.to_json
      deserialized = D2D::Client::Session.from_json(JSON.parse(serialized))
      expect(deserialized.patron.to_h).to eq(orig_patron.to_h)
    end
  end

  context 'logger' do
    it 'populates the logger' do
      # we expect an error, because nothing should
      # be listening on localhost.  But we also want to be sure
      # that if we provide our own logger during configuration,
      # that it's the one that gets used.
      log_output = capture_stdout do
        D2D::Client.configure do |config|
          config.library_symbol = 'TRLN'
          config.partnership_id = 'TRLN'
          config.base_url = 'http://localhost:1231/api'
          config.api_key = 'richard moranis'
          config.patron_id = '123456789'
          config.logger = Logger.new($stdout)
        end
        expect do
          D2D::Client::Session.new(patron_id: 'bucky')
        end.to raise_error(StandardError)
      end
      expect(log_output).to match(/Connection refused/)
    end
  end
end
