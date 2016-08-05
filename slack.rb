require 'rubygems'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = File.read("slack.token").strip
end

def sh(text)
  text.to_s.inspect
end

@topic_text = nil
def topic(topic_text)
  return if @topic_text == topic_text
  @topic_text = topic_text
  @client.web_client.channels_setTopic channel: @channel, topic: topic_text
end

def say(text)
  @client.message channel: @channel, text: text
end

@client = Slack::RealTime::Client.new

@client.on :hello do
  @channel = @client.channels.detect {|id,c| c.name == 'adventure'}[0]
end

@client.on :message do |data|
  next unless data.text =~ /\Afrotzbot/ || data.text =~ /\Af /
  if data.text == "frotzbot!"
    say "Hi <@#{data.user}>!"
    topic "testing!"
    next
  end

  command = data.text.sub(/\Afrotz\S*\s+/,"")
  command = data.text.sub(/\Af /,"")

  scene = `ruby play.rb #{sh command}`
  topic = nil

  scene_lines = scene.split("\n")
  if scene_lines[1] = ".\n"
    topic = scene_lines[0]
    scene = scene_lines[2..-1].join("\n")
  end

  topic(topic) if topic

  message = "> #{command}\n#{scene}"
  say message
end

@client.start!


