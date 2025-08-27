# Copyright © 2025 Mark Summerfield. All rights reserved.

package require ui

namespace eval app {}

proc app::main {} {
    ui::wishinit
    tk appname Charfind
    wm title . [tk appname]
    
}

