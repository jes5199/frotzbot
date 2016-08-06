require 'open3'

gamefile = File.read("current.game").strip

savedir = "history/" + gamefile
savefile = savedir + "/save.qzl"
@scenefile = savedir + "/scene.txt"
brand_new_game = ! Dir.exists?(savedir)

command_line = "./frotz/dfrotz -Z 0 -h 1000000 -p games/#{gamefile}"

game_action = ARGV[0]

def recap
  puts File.read(@scenefile)
end

def nowstamp
  Time.now.utc.to_s.gsub(/[ :]/,".")
end

case game_action
when "@recap" then
  recap
    previous_game_state = `cd #{savedir} && git rev-parse HEAD`[0..10]
    puts "_current game state is @#{game_state} _"
  exit
when /\A@/
  unless brand_new_game
    tag = game_action[1..-1].strip.sub(/_$/,"")
    previous_game_state = `cd #{savedir} && git rev-parse HEAD`[0..10]
    `cd #{savedir} && git checkout -q #{tag.strip.inspect} && git checkout -b play-#{nowstamp}`
    recap
    puts "_previous game state was @#{previous_game_state} _"
    exit
  end
end

@stdin, @stdout, @stderr, @wait_thr = Open3.popen3(command_line)

def read_content(&blk)
  while IO.select([@stdout],[],[],0.1)
    line = @stdout.readpartial(1024)
    blk && blk.(line)
  end
rescue EOFError
  return
end

def read_screen
  screen = ""
  read_content do |content|
    if content =~ /\[Hit any key.\]/
      @stdin.puts
    end
    screen << content
  end
  screen.sub!(/^.*\Z/,"")
  screen
end

def save_scene(screen)
  File.open(@scenefile, "w") do |f|
    f.print screen
  end
end

intro_text = read_screen
if brand_new_game
  Dir.mkdir(savedir) rescue nil

  print intro_text
  save_scene intro_text
  `cd #{savedir} && (git init || true) && touch .gitignore && git add scene.txt .gitignore && git commit -m "New Game" && git tag new-game && git checkout -b play-#{nowstamp}`
  exit
end

if File.exists?(savefile)
  @stdin.puts("RESTORE")
  read_screen
  @stdin.puts(savefile)
end

if game_action
  read_screen
  @stdin.puts(game_action)

  whole_content = read_screen
  print whole_content
  save_scene whole_content

  @stdin.puts("SAVE")
  @stdin.puts(savefile)
  @stdin.puts("y")
  read_content

  commit_message = "> #{game_action}"

  `cd #{savedir} && git add save.qzl scene.txt && git commit -m #{commit_message.inspect}`
end

@stdin.close
