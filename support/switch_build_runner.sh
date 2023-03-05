#!/bin/bash
set -eu -o pipefail
hash zig;
readonly error="error:";
readonly blank="      ";
readonly script_realpath="$(realpath "$0")";
readonly support_dir="$(dirname "$script_realpath")";
readonly zig_exe="$(hash -t zig)";
readonly zig_real_exe="$(realpath "$zig_exe")";
readonly zig_lib_dir="$(dirname "$zig_real_exe")/lib";
readonly zig_build_runner="$zig_lib_dir/build_runner.zig";
readonly zl_build_runner="$(realpath "$support_dir/../build_runner.zig")";
readonly zl_zig_build="$(realpath "$support_dir/../build.zig")";
readonly zig_build_runner_bkp="$zig_build_runner.bkp";

fn () 
{
    if test -L "$zig_build_runner"; then
        readonly build_runner_link_target="$(realpath "$zig_build_runner")";
        if test "$build_runner_link_target" -ef "$zl_build_runner"; then
            if test -f "$zig_build_runner_bkp"; then
                if ! rm "$zig_build_runner"; then
                    return 2;
                fi;
                if ! mv -i "$zig_build_runner_bkp" "$zig_build_runner"; then
                    return 2;
                fi;
                if test -f "$zl_zig_build"; then
                    sed -i 's/pub const build = if (false)/pub const build = if (true)/' "$zl_zig_build";
                fi;
                echo "std"
            else
                echo $error "would move back original zig build runner, but original file is missing"
                return 2;
            fi;
        else
            echo $error "expected link to zig_lib build runner, but found other file:";
            echo $blank "'$zig_build_runner' -> ";
            echo $blank "'$build_runner_link_target' != ";
            echo $blank "'$zl_build_runner'";
            return 2;
        fi;
    elif test -f "$zig_build_runner"; then
        if ! mv -i "$zig_build_runner" "$zig_build_runner_bkp"; then
            return 2;
        fi;
        if ! ln -s "$zl_build_runner" "$zig_build_runner"; then
            return 2;
        fi;
        if test -f "$zl_zig_build"; then
            sed -i 's/pub const build = if (true)/pub const build = if (false)/' "$zl_zig_build";
        fi;
        echo "zl"
    else
        echo $error "'$zig_build_runner': no such file or directory; did nothing"
    fi;
}
fn;
