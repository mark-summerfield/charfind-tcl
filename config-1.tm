# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::class create Config {
    variable Filename
    variable Geometry
}

oo::define Config constructor {{filename ""} {geometry ""}} {
    set Filename $filename
    set Geometry $geometry
}

oo::define Config classmethod load {} {
    set filename [util::get_ini_filename]
    set config [Config new]
    $config set_filename $filename
    if {[file exists $filename] && [file size $filename]} {
        set ini [ini::open $filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale 1.0]
            $config set_geometry [ini::value $ini General Geometry \
                [$config geometry]]
        } on error err {
            puts "invalid config in '$filename'; using defaults: $err"
        } finally {
            ini::close $ini
        }
    }
    return $config
}

oo::define Config method save {} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini General Scale [tk scaling]
        ini::set $ini General Geometry [wm geometry .]
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {} { return $Filename }
oo::define Config method set_filename filename { set Filename $filename }

oo::define Config method geometry {} { return $Geometry }
oo::define Config method set_geometry geometry { set Geometry $geometry }

oo::define Config method to_string {} {
    return "Config filename=$Filename scaling=[tk scaling]\
            geometry=$Geometry"
}
