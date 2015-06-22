require 'rubygems'
require 'net/http'
require 'sinatra'
require 'twilio-ruby'
require 'yaml'

token = YAML.load_file('token_id.yml')
account_sid = token["account_sid"]
auth_token = token["auth_token"]

get '/call/13103830041' do
# get '/call' do
  Twilio::TwiML::Response.new do |r|
    r.Gather :numDigits => '1', :action => '/call_confirm', :method => 'get' do |g|
      g.Say "Please press 1 to connect."
    end
  end.text
end


get '/call_confirm' do
  redirect '/call' unless ['1'].include?(params['Digits'])
  if params['Digits'] == '1'
    response = Twilio::TwiML::Response.new do |r|
      r.Dial '+13103830041', :record => 'true', :action => '/handle-record', :method => 'get'
    end
  end
  response.text
end

get '/handle-record' do

  @client = Twilio::REST::Client.new account_sid, auth_token

  Twilio::TwiML::Response.new do |r|
    puts params['RecordingUrl']
    recording_url = params['RecordingUrl']
    # recording_url = @client.account.recordings.list[0].uri
    # recording_url = recording_url[0...-4]
    recording_url += '.mp3'
    recording_url = URI(recording_url)
    puts recording_url
    # recording = Net::HTTP.get('api.twilio.com', recording_url)
    recording = Net::HTTP.get(recording_url)
    # puts recording
    puts recording.kind_of? Net::HTTPSuccess
    time = Time.now.to_s
    filename = time + '_recording.mp3'
    File.open(filename, 'w') { |file| file.write(recording)}
  end.text

  Process.kill 'TERM', Process.pid
end

@client = Twilio::REST::Client.new account_sid, auth_token

@call = @client.account.calls.create(
  :from => '+16506429888',
  :to => '+18058865375',
  :url => 'http://a241debc.ngrok.io/call/13103830041',
  :method => 'get'
)

