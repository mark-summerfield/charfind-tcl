# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::class create Config {
    variable Filename
    variable Blinking
    variable Geometry
    variable Search
    variable Clicked
}

oo::define Config constructor {{filename ""} {geometry ""}} {
    set Filename $filename
    set Blinking true
    set Geometry $geometry
    set Search "symbol"
    set Clicked ""
}

oo::define Config classmethod load {} {
    set filename [util::get_ini_filename]
    set config [Config new]
    $config set_filename $filename
    if {[file exists $filename] && [file size $filename]} {
        set ini [ini::open $filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale 1.0]
            $config set_blinking [ini::value $ini General Blinking \
                                    [$config blinking]]
            if {![$config blinking]} {
                option add *insertOffTime 0
                ttk::style configure . -insertofftime 0
            }
            $config set_geometry [ini::value $ini General Geometry \
                [$config geometry]]
            $config set_search [ini::value $ini General Search \
                [$config search]]
            $config set_clicked [ini::value $ini General Clicked \
                [$config clicked]]
        } on error err {
            puts "invalid config in '$filename'; using defaults: $err"
        } finally {
            ini::close $ini
        }
    }
    if {[$config search] eq ""} { $config set_search symbol }
    return $config
}

oo::define Config method save {} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini General Scale [tk scaling]
        ini::set $ini General Blinking [my blinking]
        ini::set $ini General Geometry [wm geometry .]
        ini::set $ini General Search [my search]
        ini::set $ini General Clicked [my clicked]
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {} { return $Filename }
oo::define Config method set_filename filename { set Filename $filename }

oo::define Config method blinking {} { return $Blinking }
oo::define Config method set_blinking blinking { set Blinking $blinking }

oo::define Config method geometry {} { return $Geometry }
oo::define Config method set_geometry geometry { set Geometry $geometry }

oo::define Config method search {} { return $Search }
oo::define Config method set_search search { set Search $search }

oo::define Config method clicked {} { return $Clicked }
oo::define Config method set_clicked clicked { set Clicked $clicked }

oo::define Config method to_string {} {
    return "Config filename=$Filename blinking=$Blinking\
        scaling=[tk scaling] geometry=$Geometry clicked=$Clicked\
        search=$Search"
}
