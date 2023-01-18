#!/bin/bash
switch_build_runner () {
    local -r script_realpath="$(/usr/bin/realpath "$0")";
    local -r support_dir="$(/usr/bin/dirname "$script_realpath")";
    local -r zig_exe="$(/usr/bin/which zig)";
    local -r zig_real_exe="$(/usr/bin/realpath "$zig_exe")";
    local -r zig_lib_dir="$(/usr/bin/dirname "$zig_real_exe")/lib";
    local -r zig_build_runner="$zig_lib_dir/build_runner.zig";
    local -r zl_build_runner="$(/usr/bin/realpath "$support_dir/../build_runner.zig")";
    local -r zl_zig_build="$(/usr/bin/realpath "$support_dir/../build.zig")";
    local -r zig_build_runner_bkp="$zig_build_runner.bkp";
    if /usr/bin/test -L "$zig_build_runner"; then
        local -r build_runner_link_target="$(/usr/bin/realpath "$zig_build_runner")";
        if /usr/bin/test "$build_runner_link_target" -ef "$zl_build_runner"; then
            if /usr/bin/test -f "$zig_build_runner_bkp"; then
                if ! /usr/bin/rm -i "$zig_build_runner"; then
                    return 2;
                fi;
                if ! /usr/bin/mv -i "$zig_build_runner_bkp" "$zig_build_runner"; then
                    return 2;
                fi;
                if /usr/bin/test -f "$zl_zig_build"; then
                    /usr/bin/sed -i 's/pub const build = if (false)/pub const build = if (true)/' "$zl_zig_build";
                fi;
            else
                echo error: "would move back original zig build runner, but original file is missing"
                return 2;
            fi;
        else
            echo error: "expected link to zig_lib build runner, but found other file: "
            echo "'$zig_build_runner' -> "
            echo "'$build_runner_link_target' != "
            echo "'$zl_build_runner'"
            return 2;
        fi;
    elif /usr/bin/test -f "$zig_build_runner"; then
        if ! /usr/bin/mv -i "$zig_build_runner" "$zig_build_runner_bkp"; then
            return 2;
        fi;
        if ! /usr/bin/ln -s "$zl_build_runner" "$zig_build_runner"; then
            return 2;
        fi;
        if /usr/bin/test -f "$zl_zig_build"; then
            /usr/bin/sed -i 's/pub const build = if (true)/pub const build = if (false)/' "$zl_zig_build";
        fi;
    else
        echo error: "'$zig_build_runner': no such file or directory; did nothing"
    fi;
}
switch_build_runner;
