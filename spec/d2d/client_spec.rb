RSpec.describe D2D::Client do
  let(:base_url) { "https://example.com/test" }
  let(:api_key) { 'some-siilly-value' }
  it 'has a version number' do
    expect(D2D::Client::VERSION).not_to be nil
  end

  it 'successfully configures given required parameters' do
    D2D::Client.configure do |c|
      c.base_url = base_url
      c.api_key = api_key
      c.library_symbol = 'NCSU'
      c.partnership_id = 'TRLN'
    end
    expect(D2D::Client.configuration.base_url).to be(base_url)
  end

  it 'fails configuration when required parameters are left out' do
    expect do
      D2D::Client.configure do |c|
        c.base_url = base_url
        c.api_key = api_key
        c.library_symbol = 'NCSU'
      end
    end.to raise_error(ArgumentError)
  end
end
