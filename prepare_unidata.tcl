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
    maybe_download
}

proc maybe_download {} {
    if {![file isfile $::DATA_FILE] || \
            [clock format [file atime $::DATA_FILE] -format %Y%m%d] != \
            [clock format now -format %Y%m%d]} {
        puts -nonewline "downloading '${::URL}' "
        set out [open $::TEMP_FILE w]
        set token [http::geturl $::URL -channel $out \
                    -progress show_progress]
        close $out
        puts ""
        const BASE [file join [zipfs root] download]
        zipfs mount $::TEMP_FILE $BASE
        foreach name [zipfs list *download/*] {
            set xmldata [readFile $name]
            break 
        }
        zipfs unmount $BASE
        read_xmldata $xmldata
    } else {
        puts "using existing data in '$::DATA_FILE'"
    }
}

proc show_progress args { puts -nonewline . ; flush stdout }

# TODO this is MISSING MOST chars!
proc read_xmldata xmldata {
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

oo::class create Char {
    variable Cp
    variable Name
    variable Words
}

oo::define Char constructor {chardata} {
    set Words [list]
    set i 0
    while {$i < [string length $chardata]} {
        set j [string first =\" $chardata $i]
        set key [string range $chardata $i [expr {$j - 1}]]
        set i [expr {$j + 2}]
        set j [string first \" $chardata $i]
        set value [string range $chardata $i [expr {$j - 1}]]
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
