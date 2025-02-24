#!/bin/tclsh

set script_path [ file dirname [ file normalize [ info script ] ] ]

set src_directory [ file join $script_path src ]
set build_directory [ file join $script_path build ]

if { ! [ file exists $src_directory ] } {
  puts "Creating source directory"
  file mkdir $src_directory
}
if { [ file exists $build_directory ] } {
  puts "Build directory already exists, removing it before re-installing or updating."
  file delete -force $build_directory
}
puts "Creating build directory"
file mkdir $build_directory

cd $src_directory

if { [ file exists [ file join $src_directory critcl ] ] } {
  puts "CriTcl source already exists, updating"
  cd [ file join $src_directory critcl ]
  exec git pull 2>@stdout >@stdout <@stdin
  cd $src_directory
} {
  puts "Pulling source for CriTcl"
  exec git clone https://github.com/andreas-kupries/critcl.git 2>@stdout >@stdout <@stdin
}
if { [ file exists [ file join $src_directory kettle ] ] } {
  puts "Kettle source already exists, updating"
  cd [ file join $src_directory kettle ]
  exec git pull 2>@stdout >@stdout <@stdin
  cd $src_directory
} {
  puts "Pulling source for Kettle"
  exec git clone https://github.com/andreas-kupries/kettle.git 2>@stdout >@stdout <@stdin
}
if { [ file exists [ file join $src_directory tclyaml ] ] } {
  puts "TclYAML source already exists, updating"
  cd [ file join $src_directory tclyaml ]
  exec git pull 2>@stdout >@stdout <@stdin
  cd $src_directory
} {
  puts "Pulling source for TclYAML"
  exec git clone https://github.com/andreas-kupries/tclyaml.git 2>@stdout >@stdout <@stdin
}

puts "Installing CriTcl"
cd [ file join $src_directory critcl ]
exec tclsh ./build.tcl install --dest-dir $build_directory 2>@stdout >@stdout <@stdin

puts "Installing Kettle"
cd [ file join $src_directory kettle ]
exec tclsh ./kettle --prefix [ file join $build_directory usr ] install 2>@stdout >@stdout <@stdin

puts "Installing TclYAML"
cd [ file join $src_directory tclyaml ]
set ::env(TCLLIBPATH) [ file join $build_directory usr lib ]
exec [ file join $build_directory usr bin kettle ] -f build.tcl --prefix [ file join $build_directory usr ] install 2>@stdout >@stdout <@stdin

puts "Installation complete!"

