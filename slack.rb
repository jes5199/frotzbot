require 'rubygems'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = File.read("slack.token").strip
end

def sh(text)
  text.to_s.inspect
end

@topic_text = (File.read("topic.txt").strip rescue nil)
def topic(topic_text)
  topic_text.strip!
  return if @topic_text == topic_text
  File.open("topic.txt","w"){|f| f.print(topic_text)}
  @topic_text = topic_text
  @client.web_client.channels_setTopic channel: @channel, topic: topic_text
end

def say(text)
  @client.message channel: @channel, text: text
end

@client = Slack::RealTime::Client.new

@client.on :hello do
  puts "Frotzbot online!"
  @channel = @client.channels.detect {|id,c| c.name == 'adventure'}[0]
end

@client.on :message do |data|
  next unless data.text =~ /\A@?frotz/ || data.text =~ /\Af /
  if data.text == "frotzbot!"
    say "Hi <@#{data.user}>!"
    topic "testing!"
    next
  end

  command = data.text
  command.sub!(/\A@?frotz\S*\s+/,"")
  command.sub!(/\Af /,"")

  scene = `ruby play.rb #{sh command}`
  topic = nil

  scene_lines = scene.split("\n")

  if scene_lines[1] == ". "
    topic = scene_lines.shift
    _ = scene_lines.shift
  elsif scene_lines[0] =~ /^\s+Lower Theater, on the bench \s+\(hot, sticky\)\s*$/
    # workaround for so-far's opening banner
    topic = scene_lines.shift
  end

  if scene_lines[-1] =~ /\A\s*_.*_\s*\Z/
    info = scene_lines.pop
  end

  scene_lines.shift while scene_lines[0] =~ /^\s*$/
  scene_lines.pop while scene_lines[-1] =~ /^\s*$/

  scene = scene_lines.join("\n")

  topic(topic) if topic

  message = "> `#{command}`\n```#{scene}```\n#{info}"
  say message
end

@client.start!


