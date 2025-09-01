# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ui

oo::class create MessageBoxForm { superclass AbstractForm }

# kind must be one of: info warning error

oo::define MessageBoxForm classmethod show {title body_text \
                                            {button_text OK} {kind info}} {
    set form [MessageBoxForm new $title $body_text $button_text $kind]
    tkwait window .one_button
}

oo::define MessageBoxForm constructor {title body_text button_text kind} {
    my make_widgets $title $body_text $button_text $kind
    my make_layout
    my make_bindings $button_text
    next .one_button [callback on_done]
    my show_modal .one_button.the_button
}

oo::define MessageBoxForm method make_widgets {title body_text button_text \
                                               kind} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .one_button
    wm resizable .one_button false false
    wm title .one_button $title
    switch $kind {
        info { set color gray92 }
        warning { set color lightyellow }
        error { set color pink }
    }
    ttk::label .one_button.label -text $body_text -background $color
    ttk::button .one_button.the_button -text $button_text -underline 0 \
        -command [callback on_done] -compound left \
        -image [ui::icon dialog-$kind.svg $size]
}

oo::define MessageBoxForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    pack .one_button.label -fill both -expand true {*}$opts
    pack .one_button.the_button -side bottom {*}$opts
}

oo::define MessageBoxForm method make_bindings kind {
    bind .one_button <Escape> [callback on_done]
    bind .one_button <Return> [callback on_done]
    bind .one_button <Alt-[string tolower [string index $kind 0]]> \
        [callback on_done]
}

oo::define MessageBoxForm method on_done {} { my delete }
