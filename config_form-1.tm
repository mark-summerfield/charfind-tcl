# Copyright © 2025 Mark Summerfield. All rights reserved.
################################################################

package require abstract_form
package require tooltip 2
package require ui

oo::class create ConfigForm {
    superclass AbstractForm

    variable Cfg
    variable Blinking
    variable Frame
}

oo::define ConfigForm constructor cfg {
    set Cfg $cfg
    set Blinking [$Cfg blinking]
    my make_widgets 
    my make_layout
    my make_bindings
    next .configForm [callback on_cancel]
    my show_modal $Frame.scaleSpinbox
}

oo::define ConfigForm method make_widgets {} {
    tk::toplevel .configForm
    wm resizable .configForm false false
    wm title .configForm "[tk appname] — Config"
    set Frame [ttk::frame .configForm.frame]
    set tip tooltip::tooltip
    ttk::label $Frame.scaleLabel -text "Application Scale" \
        -underline 12
    ttk::spinbox $Frame.scaleSpinbox -format %.2f -from 1.0 \
        -to 10.0 -increment 0.1
    $tip $Frame.scaleSpinbox "Application’s scale factor.\n\
        Restart to apply."
    $Frame.scaleSpinbox set [format %.2f [tk scaling]]
    ttk::checkbutton $Frame.blinkCheckbutton \
        -text "Cursor Blink" -underline 7 \
        -variable [my varname Blinking]
    if {$Blinking} { $Frame.blinkCheckbutton state selected }
    $tip $Frame.blinkCheckbutton \
        "Whether the text cursor should blink."
    set opts "-compound left -width 15"
    ttk::label $Frame.configFileLabel -foreground gray25 \
        -text "Config file"
    ttk::label $Frame.configFilenameLabel -foreground gray25 \
        -text [$Cfg filename] -relief sunken
    ttk::frame $Frame.buttons
    ttk::button $Frame.buttons.okButton -text OK -underline 0 \
        -compound left -image [ui::icon ok.svg $::ICON_SIZE] \
        -command [callback on_ok]
    ttk::button $Frame.buttons.cancelButton -text Cancel \
        -compound left -command [callback on_cancel] \
        -image [ui::icon gtk-cancel.svg $::ICON_SIZE]
}

oo::define ConfigForm method make_layout {} {
    const opts "-padx 3 -pady 3"
    grid $Frame.scaleLabel -row 0 -column 0 -sticky w {*}$opts
    grid $Frame.scaleSpinbox -row 0 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid $Frame.blinkCheckbutton -row 2 -column 1 -sticky we
    grid $Frame.configFileLabel -row 8 -column 0 -sticky we {*}$opts
    grid $Frame.configFilenameLabel -row 8 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid $Frame.buttons -row 9 -column 0 -columnspan 3 -sticky we
    pack [ttk::frame $Frame.buttons.pad1] -side left -expand true
    pack $Frame.buttons.okButton -side left {*}$opts
    pack $Frame.buttons.cancelButton -side left {*}$opts
    pack [ttk::frame $Frame.buttons.pad2] -side right -expand true
    grid columnconfigure $Frame 1 -weight 1
    pack $Frame -fill both -expand true
}

oo::define ConfigForm method make_bindings {} {
    bind .configForm <Escape> [callback on_cancel]
    bind .configForm <Return> [callback on_ok]
    bind .configForm <Alt-b> \
        {.configForm.frame.blinkCheckbutton invoke}
    bind .configForm <Alt-o> [callback on_ok]
    bind .configForm <Alt-s> \
        {focus .configForm.frame.scaleSpinbox}
}

oo::define ConfigForm method on_ok {} {
    tk scaling [$Frame.scaleSpinbox get]
    $Cfg set_blinking $Blinking
    my delete
}

oo::define ConfigForm method on_cancel {} { my delete }
