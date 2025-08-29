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
package require sqlite3 3
package require uri 1

# For XML format details see: https://www.unicode.org/reports/tr42/
const URL \
    http://www.unicode.org/Public/UCD/latest/ucdxml/ucd.nounihan.flat.zip
const TEMP_FILE [file join [fileutil::tempdir] \
                           [file tail [dict get [uri::split $::URL] path]]]
const UNIDATA_FILE unidata.db

proc main {} {
    set xmldata [get_chardata]
    set chars [read_xmldata $xmldata]
    write_chars $chars
}

proc get_chardata {} {
    if {![file isfile $::TEMP_FILE] || \
            [clock format [file atime $::TEMP_FILE] -format %Y%m%d] != \
            [clock format now -format %Y%m%d]} {
        puts -nonewline "downloading '${::URL}'   0%"
        flush stdout
        set out [open $::TEMP_FILE w]
        set token [http::geturl $::URL -channel $out \
                    -progress show_progress]
        close $out
        puts ""
    } else {
        puts "using existing data in '$::TEMP_FILE'"
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

proc show_progress {_ total current} {
    puts -nonewline [format "\b\b\b\b%3.0f%%" \
        [expr {$current / double($total) * 100.0}]]
    flush stdout
}

proc read_xmldata xmldata {
    puts -nonewline "reading XML data   0%"
    flush stdout
    set size [string length $xmldata]
    set one_pc [expr {$size / 100.0}]
    set pc 0.0
    set chars [list]
    set i 0
    while {$i < $size} {
        set j [string first "<char " $xmldata $i]
        if {$j == -1} { break }
        set k [string first /> $xmldata $j]
        set m [string first </char> $xmldata $j]
        if {$k == -1 || ($m != -1 && $m < $k)} { set k $m }
        set chardata [string range $xmldata [expr {$j + 6}] $k]
        set char [Char new $chardata]
        if {[$char is_valid]} { lappend chars $char }
        set new_pc [expr {$i / $one_pc}]
        if {$new_pc != $pc} {
            set pc $new_pc
            puts -nonewline [format "\b\b\b\b%3.0f%%" $pc]
            flush stdout
        }
        set i $k
    }
    puts " ([commas [llength $chars]] chars)"
    return $chars
}

proc commas n {regsub -all {\d(?=(\d{3})+($|\.))} $n {\0,}}

proc write_chars chars {
    sqlite3 db $::UNIDATA_FILE
    db transaction {
        db eval {
            DROP TABLE IF EXISTS chars;
            CREATE TABLE chars (
                cp INTEGER PRIMARY KEY NOT NULL,
                chr TEXT NOT NULL,
                name TEXT NOT NULL,
                is_symbol BOOL NOT NULL,
                CHECK(is_symbol IN (TRUE, FALSE))
            ) WITHOUT ROWID;
        }
        foreach char $chars {
            lassign [$char to_list] cp chr name is_symbol
            db eval {INSERT INTO chars (cp, chr, name, is_symbol) VALUES
                                       (:cp, :chr, :name, :is_symbol)} 
        }
    }
    db close
    puts "wrote '$::UNIDATA_FILE'"
}

oo::class create Char {
    variable Cp
    variable Name
    variable IsSymbol
}

oo::define Char constructor {data} {
    set Cp -1
    set Name ""
    set IsSymbol false
    set valid true
    set i 0
    while {$i < [string length $data]} {
        set j [string first =\" $data $i]
        set key [string range $data $i [expr {$j - 1}]]
        set i [expr {$j + 2}]
        set j [string first \" $data $i]
        set value [string range $data $i [expr {$j - 1}]]
        switch $key {
            ccc { if {$value ne "0"} { set valid false } }
            cp { set Cp [expr {"0x$value"}] }
            blk {
                switch $value {
                    Box_Drawing - Chess_Symbols - Currency_Symbols - \
                    Dingbats - Geometric_Shapes - Geometric_Shapes_Ext - \
                    Math_Operators - Misc_Arrows - Misc_Math_Symbols_A - \
                    Misc_Math_Symbols_B - Misc_Pictographs - \
                    Misc_Symbols - Misc_Technical - Ornamental_Dingbats - \
                    Sup_Arrows_A - Sup_Arrows_B - Sup_Arrows_C - \
                    Sup_Math_Operators - Sup_PUA_A - Sup_PUA_B - \
                    Sup_Punctuation - Sup_Symbols_And_Pictographs - \
                    Symbols_And_Pictographs_Ext_A - \
                    Symbols_For_Legacy_Computing - \
                    Symbols_For_Legacy_Computing_Sup - Transport_And_Map \
                        { set IsSymbol true }
                    High_PU_Surrogates - High_Surrogates - Low_Surrogates \
                        { set valid false }
                }
            }
            gc { switch $value { Sm - Sc { set IsSymbol true } } }
            Math { if {$value ne "N"} { set IsSymbol true } }
            na { set Name $value }
            OMath { if {$value ne "N"} { set IsSymbol true } }
            WSpace { if {$value ne "N"} { set valid false } }
        }
        set i [incr j 2]
    }
    if {$Name eq "" || [regexp {^(?:MODIFIER|COMBINING|VARIATION)} $Name]} {
        set valid false
    }
    if {!$valid} { set Cp -1 }
}

oo::define Char method is_valid {} { expr {$Cp > 0x20} }
oo::define Char method cp {} { return $Cp }
oo::define Char method name {} { return $Name }
oo::define Char method is_symbol {} { return $IsSymbol }

oo::define Char method to_list {} {
    list $Cp [format %c $Cp] $Name [expr {bool($IsSymbol)}]
}

oo::define Char method to_string {} {
    format "U+%06X %c '%s' %s" $Cp $Cp $Name $IsSymbol
}

main
