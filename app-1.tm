# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require ui

oo::class create App {
    variable Cfg
    variable SearchEntry
    variable ClickedEntry
    variable Tree
}

oo::define App constructor {} {
    ui::wishinit
    tk appname CharFind
    set Cfg [Config load]
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    wm geometry . [$Cfg geometry]
    raise .
    focus $SearchEntry
    update
}

oo::define App method make_ui {} {
    my prepare_ui
    my make_widgets
    my make_layout
    my make_bindings
}

oo::define App method prepare_ui {} {
    wm withdraw .
    wm title . [tk appname]
    wm iconname . [tk appname]
    catch {wm iconphoto . -default [ui::icon icon.svg]}
}

oo::define App method make_widgets {} {
    ttk::frame .topframe
    ttk::label .topframe.searchLabel -text "Search For:" -underline 7
    set SearchEntry [ttk::entry .topframe.searchEntry]
    ttk::button .topframe.searchButton -text Search -underline 0 \
        -compound left -command [callback on_search] \
        -image [ui::icon edit-find.svg $::MENU_ICON_SIZE]
    ttk::frame .treeframe
    set Tree [ttk::treeview .treeframe.tree -selectmode browse \
                -striped true -columns {chr name}]
    $Tree column 1 -stretch true
    # TODO headers
    ui::scrollize .treeframe tree vertical
    ttk::frame .bottomframe
    ttk::label .bottomframe.clickedLabel -text Clicked: -underline 4
    ttk::button .bottomframe.configButton -text Config… -width 0 \
        -underline 0 -compound left -command [callback on_config] \
        -image [ui::icon preferences-system.svg $::MENU_ICON_SIZE]
    set ClickedEntry [ttk::entry .bottomframe.clickedEntry]
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .topframe.searchLabel -side left {*}$opts
    pack $SearchEntry -side left -fill x -expand true {*}$opts
    pack .topframe.searchButton -side left {*}$opts
    pack .topframe -fill x
    pack .treeframe -fill both -expand true -padx 3
    pack .bottomframe.clickedLabel -side left {*}$opts
    pack $ClickedEntry -side left -fill x -expand true {*}$opts
    pack .bottomframe.configButton -side right {*}$opts
    pack .bottomframe -fill x
}

oo::define App method make_bindings {} {
    bind $Tree <<TreeviewSelect>> [callback on_tree_select]
    bind . <Escape> [callback on_quit]
    bind $SearchEntry <Return> [callback on_search]
    bind . <Alt-c> [callback on_config]
    bind . <Alt-k> "focus $ClickedEntry"
    bind . <Alt-f> "focus $SearchEntry"
    bind . <Alt-s> [callback on_search]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_tree_select {} {
    puts "TODO on_tree_select"
}

oo::define App method on_search {} {
    puts "TODO on_search"
}

oo::define App method on_config {} {
    puts "TODO on_config"
}

oo::define App method on_quit {} { $Cfg save ; exit }
