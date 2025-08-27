#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require fileutil 1
package require http 2
package require uri 1

const URL \
    http://www.unicode.org/Public/UCD/latest/ucdxml/ucd.nounihan.flat.zip
const TEMP_FILE [file join [fileutil::tempdir] \
                           [file tail [dict get [uri::split $::URL] path]]]
const DATA_FILE chardata.txt.gz

proc main {} {
    set xmldata [get_chardata]
    read_xmldata $xmldata
}

proc get_chardata {} {
    if {![file isfile $::TEMP_FILE] || \
            [clock format [file atime $::TEMP_FILE] -format %Y%m%d] != \
            [clock format now -format %Y%m%d]} {
        puts -nonewline "downloading '${::URL}' "
        set out [open $::TEMP_FILE w]
        set token [http::geturl $::URL -channel $out \
                    -progress show_progress]
        close $out
        puts ""
    } else {
        puts "using existing data in '$::DATA_FILE'"
    }
    const BASE [file join [zipfs root] download]
    zipfs mount $::TEMP_FILE $BASE
    foreach name [zipfs list *download/*] {
        set xmldata [readFile $name]
        break 
    }
    zipfs unmount $BASE
    return $xmldata
}

proc show_progress args { puts -nonewline . ; flush stdout }

# TODO this is MISSING MOST chars!
# TODO switch to:
#   regexp -indicies -start $i {<char(.*?)>.*?</char>} $xmldata _ indexes
proc read_xmldata xmldata {
    puts "read_xmldata xmldata(len)=[string length $xmldata]"
    set chars [list]
    set i 0
    while {$i < [string length $xmldata]} {
        set i [string first <char $xmldata $i]
        if {$i == -1} { break }
        incr i 6
        set j [string first </char> $xmldata $i]
        if {$j == -1} { break }
        set k [string first > $xmldata $i]
        set chardata [string range $xmldata $i [expr {$k - 1}]]
        set char [Char new $chardata]
        if {[$char cp] > 0x20} { lappend chars $char }
        set i [incr j]
    }
    set data [list]
    foreach char $chars {
        lappend data [$char to_tsv]
    }
    writeFile $::DATA_FILE binary [zlib gzip [join $data \n] -level 9]
}

# TODO separate into char-1.tm
oo::class create Char {
    variable Cp
    variable Name
    variable Words
}

oo::define Char constructor {data} {
    # if {[string match U+ $data]} { # parse to_string text } else
    set Words [list]
    set i 0
    while {$i < [string length $data]} {
        set j [string first =\" $data $i]
        set key [string range $data $i [expr {$j - 1}]]
        set i [expr {$j + 2}]
        set j [string first \" $data $i]
        set value [string range $data $i [expr {$j - 1}]]
        switch $key {
            cp { set Cp [expr {"0x$value"}] }
            na { set Name $value }
        }
        set i [incr j 2]
    }
}

oo::define Char method cp {} { return $Cp }
oo::define Char method name {} { return $Name }
oo::define Char method words {} { return $Words }

oo::define Char method to_tsv {} {
    return "$Cp\t$Name\t[join $Words \v]"
}

oo::define Char method to_string {} {
    format "U+%06X '%s' {%s}" $Cp $Name [join $Words ,]
}

main
