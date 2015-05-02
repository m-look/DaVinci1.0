#!/bin/sh

#define some static stuff
machine="daVinciF10"
version="14100714"
filamentid="41,41"

# figure out some stuff about the file and it's name
path=${1%/*.*}
file=${1##*/}
file_base=${file%*.*}
file_suff=${file##*.}
file_out=${path}/${file_base}_xyz.gcode

# we don't wish to proceed unless this thing is actually a file
if [ -f "$1" ]; then

# even then we want it to be a file ending in .gcode
  if [ $file_suff = "gcode"  ]; then

#read the contents of the file and process each line
    layer_count=0
    while read line; do
      #find layer height
      if [[ "$line" =~ ^\;\ layer_height.* ]]; then
        #echo $line
        layer_height=${line##*\=\ }
      #find filament used
      elif [[ "$line" =~ ^\;\ filament\ used ]]; then
        fil_used=${line##*\=\ }
        fil_used=${fil_used%mm*}
        print_time=${fil_used%.*}
      #find fill density
      elif [[ "$line" =~ ^\;\ fill_density ]]; then
        fill_density=${line##*\=\ }
        if [[ "$fill_density" =~ \%$ ]]; then
          fill_density=${fill_density%\%*}
          fill_density="0.${fill_density}"
        fi
      #find raft layers
      elif [[ "$line" =~ ^\;\ raft_layers ]]; then
        raft_layers=${line##*\=\ }
      elif [[ "$line" =~ ^\;\ support_material\  ]]; then
        support_material=${line##*\=\ }
      elif [[ "$line" =~ ^\;\ support_material_extruder ]]; then
        support_mat_extruder=${line##*\=\ }
      elif [[ "$line" =~ ^\;\ perimeter_extruder ]]; then
        perimeter_extruder=${line##*\=\ }
      elif [[ "$line" =~ ^\;\ perimeters ]]; then
        perimeters=${line##*\=\ }
      elif [[ "$line" =~ ^\;\ speed\  ]]; then
        speed=${line##*\=\ }
      #count layer changes
      elif [[ "$line" =~ ^G1\ Z ]]; then
        ((layer_count++))
      fi
    done < $1

    #start printing header information
    echo "; filename = $file" > $file_out
    echo "; machine = $machine" >> $file_out
    echo "; filamentid = $filamentid" >> $file_out
    printf "; layer_height = %.2f\n" $layer_height >> $file_out
    printf "; fill_density = %.2f\n" $fill_density >> $file_out
    echo "; raft_layers = $raft_layers" >> $file_out
    echo "; support_material = $support_material" >> $file_out
    echo "; support_material_extruder = ${support_mat_extruder}" >> $file_out
    echo "; support_density = $fill_density" >> $file_out
    echo "; shells = $perimeters" >> $file_out
    echo "; shells = $speed" >> $file_out
    echo "; total_layers = $layer_count" >> $file_out
    echo "; version = $version" >> $file_out
    printf "; total_filament = %.2f\n" $fil_used >> $file_out
    echo "; extruder = $perimeter_extruder" >> $file_out
    echo "; print_time = $print_time" >> $file_out
    
    #strip comments and dump contents of the original file after our header
    cat $1 | grep -v ^\;\ | grep -v ^$ >> $file_out 

  #if directory exists save error about not being a gcode file
  else
    if [ -d "$path" ]; then
      echo "Not a gcode file: $1" >> $path/${file_base}_post.err
    fi 
  fi

#if directory exists file not found error
else
    if [ -d "$path" ]; then
      echo "File not found: $1" >> $path/${file_base}_post.err
    fi
fi
