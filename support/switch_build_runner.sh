#!/bin/bash
set -eu -o pipefail
hash zig;
readonly error="error:";
readonly warn="warn: ";
readonly blank="      ";
readonly script_realpath="$(realpath "$0")";
readonly support_dir="$(dirname "$script_realpath")";
readonly zig_exe="$(hash -t zig)";
readonly zig_real_exe="$(realpath "$zig_exe")";
readonly zig_install_lib_dir="$(dirname "$zig_real_exe")/lib";
readonly std_build_runner="$zig_install_lib_dir/build_runner.zig";
readonly zl_build_runner="$(realpath "$support_dir/../build_runner.zig")";
readonly zl_zig_build="$(realpath "$support_dir/../build.zig")";
readonly std_build_runner_bkp="$std_build_runner.bkp";

fn () 
{
    if test -L "$std_build_runner"; then
        readonly build_runner_link_target="$(realpath "$std_build_runner")";
        if test "$build_runner_link_target" -ef "$zl_build_runner"; then
            if test -f "$std_build_runner_bkp"; then
                if ! rm "$std_build_runner"; then
                    return 2;
                fi;
                if ! mv -i "$std_build_runner_bkp" "$std_build_runner"; then
                    return 2;
                fi;
                if test -f "$zl_zig_build"; then
                    sed -i 's/pub const build = if (false)/pub const build = if (true)/' "$zl_zig_build";
                fi;
                echo "builder = zl => std"
            else
                echo $error "would move back original zig build runner, but original file is missing"
                return 2;
            fi;
        elif [[ "$build_runner_link_target" == */zig_lib* ]]; then
            readonly other_zl_zig_build="$(dirname "$build_runner_link_target")/build.zig";
            if ! test -f "$zl_zig_build"; then
                echo $error "'$other_zl_zig_build': no such file or directory; did nothing"
                return 2;
            fi;
            if test -f "$other_zl_zig_build"; then
                if ! sed -i 's/pub const build = if (false)/pub const build = if (true)/' "$other_zl_zig_build"; then
                    return 2;
                fi;
            else
                echo $warn "replacing bad link"
            fi;
            if ! sed -i 's/pub const build = if (true)/pub const build = if (false)/' "$zl_zig_build"; then
                return 2;
            fi;
            if ! rm "$std_build_runner"; then
                return 2;
            fi;
            if ! ln -s "$zl_build_runner" "$std_build_runner"; then
                return 2;
            fi;
            echo "builder = zl => zl"
        else
            echo $error "expected link to zig_lib build runner, but found other file:";
            echo $blank "'$std_build_runner' -> ";
            echo $blank "'$build_runner_link_target' != ";
            echo $blank "'$zl_build_runner'";
            return 2;
        fi;
    elif test -f "$std_build_runner"; then
        if ! mv -i "$std_build_runner" "$std_build_runner_bkp"; then
            return 2;
        fi;
        if ! ln -s "$zl_build_runner" "$std_build_runner"; then
            return 2;
        fi;
        if test -f "$zl_zig_build"; then
            sed -i 's/pub const build = if (true)/pub const build = if (false)/' "$zl_zig_build";
        fi;
        echo "builder = std => zl"
    else
        echo $error "'$std_build_runner': no such file or directory"
        if test -f "$std_build_runner_bkp"; then
            if ! mv -i "$std_build_runner_bkp" "$std_build_runner"; then
                return 2;
            fi;
            echo "builder = null => std"
        fi;
    fi;
}
fn;
