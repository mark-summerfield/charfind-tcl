# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require tooltip 2
package require ui

oo::class create ConfigForm {
    superclass AbstractForm

    variable Cfg
    variable Blinking
}

oo::define ConfigForm constructor cfg {
    set Cfg $cfg
    set Blinking [$Cfg blinking]
    my make_widgets 
    my make_layout
    my make_bindings
    next .configForm [callback on_cancel]
    my show_modal .configForm.scaleSpinbox
}

oo::define ConfigForm method make_widgets {} {
    tk::toplevel .configForm
    wm resizable .configForm false false
    wm title .configForm "[tk appname] — Config"
    set tip tooltip::tooltip
    ttk::label .configForm.scaleLabel -text "Application Scale" \
        -underline 12
    ttk::spinbox .configForm.scaleSpinbox -format %.2f -from 1.0 -to 10.0 \
        -increment 0.1
    $tip .configForm.scaleSpinbox "Application’s scale factor.\n\
        Restart to apply."
    .configForm.scaleSpinbox set [format %.2f [tk scaling]]
    ttk::checkbutton .configForm.blinkCheckbutton -text "Cursor Blink" \
        -underline 7 -variable [my varname Blinking]
    if {$Blinking} { .configForm.blinkCheckbutton state selected }
    $tip .configForm.blinkCheckbutton \
        "Whether the text cursor should blink."
    set opts "-compound left -width 15"
    ttk::label .configForm.configFileLabel -foreground gray25 \
        -text "Config file"
    ttk::label .configForm.configFilenameLabel -foreground gray25 \
        -text [$Cfg filename] -relief sunken
    ttk::frame .configForm.buttons
    ttk::button .configForm.buttons.okButton -text OK -underline 0 \
        -compound left -image [ui::icon ok.svg $::ICON_SIZE] \
        -command [callback on_ok]
    ttk::button .configForm.buttons.cancelButton -text Cancel \
        -compound left -image [ui::icon gtk-cancel.svg $::ICON_SIZE] \
        -command [callback on_cancel]
}

oo::define ConfigForm method make_layout {} {
    const opts "-padx 3 -pady 3"
    grid .configForm.scaleLabel -row 0 -column 0 -sticky w {*}$opts
    grid .configForm.scaleSpinbox -row 0 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid .configForm.blinkCheckbutton -row 2 -column 1 -sticky we
    grid .configForm.configFileLabel -row 8 -column 0 -sticky we {*}$opts
    grid .configForm.configFilenameLabel -row 8 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid .configForm.buttons -row 9 -column 0 -columnspan 3 -sticky we
    pack [ttk::frame .configForm.buttons.pad1] -side left -expand true
    pack .configForm.buttons.okButton -side left {*}$opts
    pack .configForm.buttons.cancelButton -side left {*}$opts
    pack [ttk::frame .configForm.buttons.pad2] -side right -expand true
    grid columnconfigure .configForm 1 -weight 1
}

oo::define ConfigForm method make_bindings {} {
    bind .configForm <Escape> [callback on_cancel]
    bind .configForm <Return> [callback on_ok]
    bind .configForm <Alt-b> {.configForm.blinkCheckbutton invoke}
    bind .configForm <Alt-o> [callback on_ok]
    bind .configForm <Alt-s> {focus .configForm.scaleSpinbox}
}

oo::define ConfigForm method on_ok {} {
    tk scaling [.configForm.scaleSpinbox get]
    $Cfg set_blinking $Blinking
    my delete
}

oo::define ConfigForm method on_cancel {} { my delete }
