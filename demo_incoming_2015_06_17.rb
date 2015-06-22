require 'rubygems'
require 'net/http'
require 'sinatra'
require 'twilio-ruby'
require 'yaml'

token = YAML.load_file('token_id.yml')
account_sid = token["account_sid"]
auth_token = token["auth_token"]

get '/' do
  people = {
    '+18058865375' => 'Yuanyang Zhang', # tenant
    '+18608800079' => 'Dear Owner', # owner
    '+14158675311' => 'Virgil',
    '+14158675312' => 'Marcel'
  }
  name = people[params['From']] || 'Dear Friend'

  if name == 'Yuanyang Zhang'
    Twilio::TwiML::Response.new do |r|
      r.Say "Hello #{name}, good morning."
      r.Gather :numDigits => '1', :action => '/tenants', :method => 'get' do |g|
        g.Say 'Maintainance, press 1.'
        g.Say 'Other issues to talk with your leasing office, press 2.'
        g.Say 'Press any other key to start over.'
      end
    end.text
  elsif name == 'Dear Owner'
    Twilio::TwiML::Response.new do |r|
      r.Say "Hello #{name}, good morning."
      r.Say 'We are directing you to a property manager, please wait.'
      r.Dial '+18058865375', :record => 'true', :action => '/handle-record', :method => 'get'
    end.text
  else
    Twilio::TwiML::Response.new do |r|
      r.Say "Hello #{name}, good morning."
      r.Gather :numDigits => '1', :action => '/others', :method => 'get' do |g|
        g.Say 'To speak with our leasing office, press 1.'
        g.Say 'To speak with our representative in our company, press 2.'
        g.Say 'Press any other key to start over.'
      end
    end.text
  end
end

get '/tenants' do
  redirect '/' unless ['1', '2'].include?(params['Digits'])
  if params['Digits'] == '1' 
    response = Twilio::TwiML::Response.new do |r|
      r.Say 'Please tell us your unit number, your maintainance request and whenther you would like us to fix it with our key.'
      r.Record :maxLength => '30', :action => '/maintainance', :method => 'get'
    end
  elsif params['Digits'] == '2' 
    response = Twilio::TwiML::Response.new do |r|
      r.Dial '+18058865375', :record => 'true', :action => '/handle-record', :method => 'get'
      r.Say 'The call failed or the remote party hung up. Goodbye.'
    end
  end
  response.text
end

get '/others' do 
  redirect '/' unless ['1', '2'].include?(params['Digits'])
  if params['Digits'] == '1' 
    response = Twilio::TwiML::Response.new do |r|
      r.Dial '+18058865375', :record => 'true', :action => '/handle-record', :method => 'get'
      r.Say 'The call failed or the remote party hung up. Goodbye.'
    end
  elsif params['Digits'] == '2' 
    response = Twilio::TwiML::Response.new do |r|
      r.Dial '+18058865375', :record => 'true', :action => '/handle-record', :method => 'get'
      r.Say 'The call failed or the remote party hung up. Goodbye.'
    end
  end
  response.text
end


get '/handle-record' do
  @client = Twilio::REST::Client.new account_sid, auth_token

  Twilio::TwiML::Response.new do |r|
    puts params['RecordingUrl']
    recording_url = params['RecordingUrl']
    recording_url += '.mp3'
    puts recording_url

    call_sid = params['DialCallSid']
    puts call_sid

    call_status = params['DialCallStatus']
    puts call_status

    call_duration = params['DialCallDuration']
    puts call_duration

    recording_url = URI(recording_url)
    recording = Net::HTTP.get(recording_url)
    # puts recording
    puts recording.kind_of? Net::HTTPSuccess
    time = Time.now.to_s
    filename = time + '_recording.mp3'
    File.open(filename, 'w') { |file| file.write(recording)}
  end.text
end

get '/maintainance' do
  Twilio::TwiML::Response.new do |r|
    recording_url = params['RecordingUrl']
    recording_url += '.mp3'
    recording = Net::HTTP.get('api.twilio.com', recording_url)
    time = Time.now.to_s
    filename = 'maintainance_' + time + '_recording.mp3'
    File.open(filename, 'w') { |file| file.write(recording)}
  end.text
end
