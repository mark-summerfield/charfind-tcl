# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require config_form
package require sqlite3 3
package require textutil::string
package require ui
package require util

oo::class create App {
    variable Cfg
    variable SearchCombo
    variable ClickedEntry
    variable Tree
    variable StatusLabel
}

oo::define App constructor {} {
    ui::wishinit
    tk appname CharFind
    set Cfg [Config load]
    my make_ui
    my on_search
}

oo::define App method show {} {
    wm deiconify .
    wm geometry . [$Cfg geometry]
    raise .
    focus $SearchCombo
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
    set search [$Cfg search]
    set SearchCombo [ttk::combobox .topframe.searchCombo -values \
        [lsort -dictionary -unique \
            "$search check ballot bullet greek math sign symbol"]]
    $SearchCombo set $search
    $SearchCombo selection range 0 end
    ttk::button .topframe.searchButton -text Search -underline 0 \
        -compound left -command [callback on_search] \
        -image [ui::icon edit-find.svg $::MENU_ICON_SIZE]
    my make_tree
    ttk::frame .bottomframe
    ttk::label .bottomframe.clickedLabel -text Clicked: -underline 4
    ttk::button .bottomframe.configButton -text Config… -width 0 \
        -underline 0 -compound left -command [callback on_config] \
        -image [ui::icon preferences-system.svg $::MENU_ICON_SIZE]
    set ClickedEntry [ttk::entry .bottomframe.clickedEntry]
    $ClickedEntry insert 0 [$Cfg clicked]
    set StatusLabel [ttk::label .statusLabel -relief sunken]
}

oo::define App method make_tree {} {
    ttk::frame .treeframe
    set Tree [ttk::treeview .treeframe.tree -selectmode browse \
                -striped true -columns {chr name}]
    set cwidth [font measure TkDefaultFont W]
    $Tree column #0 -width [expr {$cwidth * 3}] -stretch false \
        -anchor center
    $Tree column 0 -width [expr {$cwidth * 7}] -stretch false -anchor center
    $Tree column 1 -stretch true
    $Tree heading #0 -text Chr
    $Tree heading 0 -text U+
    $Tree heading 1 -text Name
    ui::scrollize .treeframe tree vertical
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .topframe.searchLabel -side left {*}$opts
    pack $SearchCombo -side left -fill x -expand true {*}$opts
    pack .topframe.searchButton -side left {*}$opts
    pack .topframe -fill x
    pack .treeframe -fill both -expand true -padx 3
    pack .bottomframe.clickedLabel -side left {*}$opts
    pack $ClickedEntry -side left -fill x -expand true {*}$opts
    pack .bottomframe.configButton -side right {*}$opts
    pack .bottomframe -fill x
    pack .statusLabel -fill x
}

oo::define App method make_bindings {} {
    bind $SearchCombo <<ComboboxSelected>> [callback on_search]
    bind $Tree <<TreeviewSelect>> [callback on_tree_select]
    bind . <Escape> [callback on_quit]
    bind $SearchCombo <Return> [callback on_search]
    bind . <Alt-c> [callback on_config]
    bind . <Alt-k> [callback on_clicked]
    bind . <Alt-f> "focus $SearchCombo"
    bind . <Alt-s> [callback on_search]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_tree_select {} {
    set sel [$Tree selection]
    set c [$Tree item $sel -text]
    $ClickedEntry insert end $c
}

oo::define App method on_clicked {} {
    focus $ClickedEntry
    $ClickedEntry selection range 0 end
}

oo::define App method on_search {} {
    $Tree delete [$Tree children {}]
    set what [$SearchCombo get]
    if {$what eq ""} {
        $StatusLabel configure -text "Enter a search for term…"
        return
    }
    set values [$SearchCombo cget -values]
    lappend values $what
    $SearchCombo configure -values [lsort -dictionary -unique $values]
    set what [string toupper $what]
    sqlite3 db $::UNIDATA_FILE -readonly true
    if {[string match SYM* $what]} {
        db eval {SELECT chr, cp, name FROM chars WHERE is_symbol = TRUE
                 ORDER BY cp} {
            my add_row $chr $cp $name
        }
    } else {
        set what %$what%
        db eval {SELECT chr, cp, name FROM chars WHERE name LIKE :what
                 ORDER BY cp} {
            my add_row $chr $cp $name
        }
    }
    db close
    set count [llength [$Tree children {}]]
    if {!$count} {
        $StatusLabel configure -text "No matching characters found"
    } else {
        lassign [util::n_s $count true] n s
        $StatusLabel configure -text "Found $n matching character$s"
    }
}

oo::define App method add_row {chr cp name} {
    set name [textutil::string::capEachWord [string tolower $name]]
    $Tree insert {} end -text $chr -values "[format %04X $cp] {$name}"
}

oo::define App method on_config {} { ConfigForm new $Cfg }

oo::define App method on_quit {} {
    $Cfg set_search [$SearchCombo get]
    $Cfg set_clicked [$ClickedEntry get]
    $Cfg save
    exit
}
