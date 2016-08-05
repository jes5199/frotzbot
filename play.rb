require 'open3'

gamefile = "SoFar.z8"

savedir = "history/" + gamefile
savefile = savedir + "/save.qzl"
@scenefile = savedir + "/scene.txt"

command_line = "./frotz/dfrotz -Z 0 -h 1000000 -p games/#{gamefile}"

@stdin, @stdout, @stderr, @wait_thr = Open3.popen3(command_line)

game_action = ARGV[0]

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

show_intro = ! Dir.exists?(savedir)

intro_text = read_screen
if show_intro
  Dir.mkdir(savedir) rescue nil

  print intro_text
  save_scene intro_text
  `cd #{savedir} && (git init || true) && touch .gitignore && git add scene.txt .gitignore && git commit -m "New Game" && git tag new-game`
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
  `cd #{savedir} && git add save.qzl scene.txt && git commit -m #{game_action.inspect}`
end

@stdin.close
