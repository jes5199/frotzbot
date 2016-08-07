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
  @user = @client.users.detect {|id,c| c.name == 'frotzbot'}[0]
  puts "user #{@user} in channel #{@channel}"
end

@client.on :message do |data|
  command = data.text
  command = command.lstrip
  next unless command =~ /\Afrotz/i || command =~ /\Af( |\Z)/i || command.start_with?("<@#{@user}>")
  if command == "frotzbot!"
    say "Hi <@#{data.user}>!"
    topic "testing!"
    next
  end

  command.sub!(/\A<@#{@user}>\S*\s*/,"")
  command.sub!(/\Afrotz\S*\s*/i,"")
  command.sub!(/\Af(\s+|\Z)/i,"")

  puts command

  scene = `ruby play.rb #{sh command}`
  topic = nil

  scene_lines = scene.split("\n")

  # dfrotz represents control characters by putting symbols in column 0
  if scene_lines[1] == ". "
    topic = scene_lines.shift
    _ = scene_lines.shift
  elsif scene_lines.any?{|line| line.start_with?(") ")}
    index = scene_lines.find_index{|line| line.start_with?(") ")}
    topic = scene_lines.delete_at(index).sub(") ","  ")
    scene_lines.reject!{|line| line == ". "}
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
  
  message = "> `#{command}`\n"
  message += "```#{scene.gsub("\n  [Hit any key.]\n","```\n...\n```")}```\n".gsub("``````","")
  message += "\n#{info}"
  say message
end

@client.start!


