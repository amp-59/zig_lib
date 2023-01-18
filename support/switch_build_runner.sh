#!/bin/bash
switch_build_runner () {
    local -r script_realpath="$(/usr/bin/realpath "$0")";
    local -r support_dir="$(/usr/bin/dirname "$script_realpath")";
    local -r zig_exe="$(/usr/bin/which zig)";
    local -r zig_real_exe="$(/usr/bin/realpath "$zig_exe")";
    local -r zig_lib_dir="$(/usr/bin/dirname "$zig_real_exe")/lib";
    local -r zig_build_runner="$zig_lib_dir/build_runner.zig";
    local -r zl_build_runner="$(/usr/bin/realpath "$support_dir/../build_runner.zig")";
    local -r zig_build_runner_bkp="$zig_build_runner.bkp";
    if /usr/bin/test -L "$zig_build_runner"; then
        local -r build_runner_link_target="$(/usr/bin/realpath "$zig_build_runner")";
        if /usr/bin/test "$build_runner_link_target" -ef "$zl_build_runner"; then
            if /usr/bin/test -f "$zig_build_runner_bkp"; then
                /usr/bin/rm -i "$zig_build_runner";
                /usr/bin/mv -i "$zig_build_runner_bkp" "$zig_build_runner"
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
        /usr/bin/mv -i "$zig_build_runner" "$zig_build_runner_bkp"
        /usr/bin/ln -s "$zl_build_runner" "$zig_build_runner"
    fi;
}
switch_build_runner;
