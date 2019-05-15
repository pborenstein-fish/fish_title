# Tool that sets the iTerm2 tab title
# and tab color
#
# * Special titles & colors for specific directories
# * Special titles & colors for long running processes
#
#   Per-directory titles get set when the fish_prompt
#   event fires: function --on-event fish_prompt do_fish_prompt
#
#   Per-process titles get set when the fish_preexec
#   event fires: function --on-event fish_preexec do_preexec


#   we call tab_color here to load the tab_<color> functions
#   and to set the tab color to the default

tab_color

#   The default window title gets set:
#
#   * before a command is executed
#   * before the prompt is printed
#
#   If fish_title isn't defined, fish uses the
#   default: "echo $_ \" \"; __fish_pwd"
#
#   The problem is that the function that uses
#   fish_title (reader_write_title()) sends
#   the escape sequence to set the titles.
#   This makes it impossible to set the
#   tab color in the fish_title function
#
#   See: https://fishshell.com/docs/current/index.html#title


function fish_title
  #   we disable fish's normal title handling
  #   by ensuring it returns nothing
end

set fish_prompt_pwd_dir_length 3  # number of chars per directory
set tab_default_override "no"     # if no: reset color to tab_default
                                  # if yes: leave it alone

set -l smallhost (string replace -r '\..+' '' $hostname)


set -l FISH_TITLES_CSV  "$HOME/.config/fish_titles.csv"

set FISH_TITLES_CSV "$HOME/.config/fish/conf.d/titles."$smallhost

set -l directory   # array of directories
set -l title       # array of titles
set -l color       # array of colors

# set up the directory, title, color arrays
while read --delimiter=, _directory _title _color
  set _directory (string trim $_directory)
  set _title     (string trim $_title)
  set _color     (string trim $_color)

  [ -z $_directory$_title$_color ] && continue

  set directory $directory $_directory
  set title     $title     $_title
  set color     $color     $_color
end < $FISH_TITLES_CSV



#   Now we write a title function that
#   * sets the window title
#   * sets the tab color

function my_fish_title

  # the default title string is the abbreviated PWD
  set -l title_string (prompt_pwd)

  # HOME is a special case
  if test $HOME = $PWD
    tab_deep_sky_blue
    do_title $title_string
    return
  end

  # Are we in one of the special directories?
  set ix 1
  for d in $directory
    if set m (string match -r $d $PWD)
      break
    end
    set ix (math $ix + 1)
  end

  # If we are, use the title and color from settings
  if test $ix -le (count $directory)
    if test (count $m) -eq 2
        set title_string (string replace XX $m[2] $title[$ix])
    else
        set title_string $title[$ix]
    end
    eval $color[$ix]
    do_title $title_string
    return
  end

  do_title $title_string
  
  if test $tab_default_override != "yes"
    tab_default
  end
end

function do_title --argument-names title_string
  echo -ne "\e]0;$title_string\a"
end

function do_fish_prompt --on-event fish_prompt 
  my_fish_title
end

function do_preexec --on-event fish_preexec 
  # $_ is the command being run, usually fish
  # $argv is the command line
  set xyzzy $_ $argv
  if string match -qr "jekyll.*serve" $xyzzy
    do_title "jekyll"
    tab_golden_rod
  else if string match -qr "run.py" $xyzzy
    do_title "edit-server"
    tab_golden_rod
  else if string match -qr "python -m SimpleHTTPServer" $xyzzy
    do_title "SIMPLE"
    tab_golden_rod
  end
end

