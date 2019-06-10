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

set -l FISH_TITLES_CSV  "$HOME/.config/fish_titles.csv"

set -l smallhost (string replace -r '\..+' '' $hostname)
set FISH_TITLES_CSV "$HOME/.config/fish/conf.d/titles."$smallhost

set directory   # array of directories
set title       # array of titles
set color       # array of colors

# set up the directory, title, color arrays
while read --delimiter=, _directory _title _color
  set _directory (string trim $_directory)
  set _title (string trim $_title)
  set _color (string trim $_color)
  if test -z $_directory$_title$_color
    continue
  end

  if [ (string sub -l1 $_directory) = '$' ]
    set _directory (string sub -s 2 $_directory)
    set _directory "^$$_directory\$"
  end

  set directory $directory $_directory
  set title $title $_title
  set color $color $_color
end < $FISH_TITLES_CSV


#   first we disable fish's normal title handling
#   by ensuring it returns nothing

function fish_title
end

# for prompt_pwd: number of characters per directory
set fish_prompt_pwd_dir_length 3

# if 'yes', does not change the color of the tab
# if anything else, change color to tab_default

set sticky_tab_color "no"

#   Now we write a title function that
#   * sets the window title
#   * sets the tab color

set TITLE_FILE './title.file'

function my_fish_title
    # the default title string is the abbreviated PWD
  set -l title_string (prompt_pwd)

  if test -e $TITLE_FILE
      # read the file: name, color
      tab_lime
      do_title $title_string
      return
  end

  # Are we in one of the special directories?
  set ix 1
  for d in $directory
    if set m (string match -r "$d" "$PWD")
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

  # reset the color every time unless it's sticky
  if test $sticky_tab_color != "yes"
    tab_default
  end

  do_title "$title_string"  
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
    tab_golden_rod
    do_title "jekyll"
  else
    tab_golden_rod
    do_title $argv
  end
end

