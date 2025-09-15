# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ui
package require util

oo::class create AboutForm {
    superclass AbstractForm
}

oo::define AboutForm constructor {} {
    my make_widgets
    my make_layout
    my make_bindings
    next .aboutForm [callback on_close]
    my show_modal .aboutForm.frame.closeButton
}

oo::define AboutForm method make_widgets {} {
    tk::toplevel .aboutForm
    wm title .aboutForm "[tk appname] — About"
    wm resizable .aboutForm false false
    set height 15
    ttk::frame .aboutForm.frame
    set background [ttk::style lookup TFrame -background]
    tk::text .aboutForm.frame.text -width 50 -height $height \
        -wrap word -spacing1 3 -spacing3 3 -relief flat \
        -background $background
    my Populate
    .aboutForm.frame.text configure -state disabled
    ttk::button .aboutForm.frame.closeButton -text Close \
        -compound left -command [callback on_close] \
        -image [ui::icon close.svg $::ICON_SIZE]
}

oo::define AboutForm method make_layout {} {
    grid .aboutForm.frame.text -sticky nsew -pady 3
    grid .aboutForm.frame.closeButton -pady 3
    pack .aboutForm.frame -fill both -expand true
}

oo::define AboutForm method make_bindings {} {
    bind .aboutForm <Escape> [callback on_close]
    bind .aboutForm <Return> [callback on_close]
    .aboutForm.frame.text tag bind url <Double-1> \
        [callback on_click_url @%x,%y]
}

oo::define AboutForm method on_click_url index {
    set indexes [.aboutForm.frame.text tag prevrange url $index]
    set url [string trim [.aboutForm.frame.text \
            get {*}$indexes]]
    if {$url ne ""} {
        if {![string match -nocase http*://* $url]} {
            set url [string cat http:// $url]
        }
        util::open_webpage $url
    }
}

oo::define AboutForm method on_close {} { my delete }

oo::define AboutForm method Populate {} {
    set txt .aboutForm.frame.text
    my AddTextTags $txt
    set img [$txt image create end -align center \
             -image [ui::icon icon.svg 64]]
    $txt tag add spaceabove $img
    $txt tag add center $img
    set add [list $txt insert end]
    {*}$add "\n[tk appname] $::VERSION\n" {center title}
    {*}$add "A Unicode character finder.\n\n" {center navy}
    set year [clock format [clock seconds] -format %Y]
    if {$year > 2025} {
        set year "2025-[string range $year end-1 end]"
    }
    set bits [expr {8 * $::tcl_platform(wordSize)}]
    if {[tk windowingsystem] eq "x11"} {
        set distro [exec lsb_release -ds]
    }
    {*}$add \
        "https://github.com/mark-summerfield/charfind-tcl\n" \
        {center green url}
    {*}$add "Copyright © $year Mark Summerfield.\nAll\
        Rights Reserved.\n" {center green}
    {*}$add "License: GPLv3.\n" {center green}
    {*}$add "[string repeat " " 60]\n" {center hr}
    {*}$add "Tcl/Tk $::tcl_patchLevel (${bits}-bit)\n" center
    if {[info exists distro] && $distro != ""} {
        {*}$add "$distro\n" center
    }
    {*}$add "$::tcl_platform(os) $::tcl_platform(osVersion)\
        ($::tcl_platform(machine))\n" center
}

oo::define AboutForm method AddTextTags txt {
    set margin 12
    $txt configure -font TkTextFont
    set cmd [list $txt tag configure]
    {*}$cmd spaceabove -spacing1 6
    {*}$cmd margins -lmargin1 $margin -lmargin2 $margin \
        -rmargin $margin
    {*}$cmd center -justify center
    {*}$cmd title -foreground navy -font H1
    {*}$cmd gray -foreground gray
    {*}$cmd navy -foreground navy
    {*}$cmd green -foreground darkgreen
    {*}$cmd bold -font bold
    {*}$cmd italic -font italic
    {*}$cmd url -underline true -underlinefg darkgreen
    {*}$cmd hr -overstrike true -overstrikefg lightgray \
        -spacing3 10
}
