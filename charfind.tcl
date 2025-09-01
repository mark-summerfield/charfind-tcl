#!/usr/bin/env wish9
# Copyright © 2025 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require app

const VERSION 1.0.0
const UNIDATA_FILE [file join $APPPATH unidata.db]

if {![file isfile $::UNIDATA_FILE]} {
    puts "run prepare_unidata.tcl to generate unidata.db"
    exit 1
}

set app [App new]
$app show
