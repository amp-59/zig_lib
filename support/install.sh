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
readonly zig_lib_dir="$(dirname "$support_dir")";
readonly zig_lib_dir_link="$zig_install_lib_dir/zig_lib";
readonly std_build_runner="$zig_install_lib_dir/build_runner.zig";
readonly std_build_runner_to="$zig_install_lib_dir/std_build_runner.zig";
readonly zl_build_runner="$(realpath "$support_dir/../build_runner.zig")";
readonly zl_zig_build="$(realpath "$support_dir/../build.zig")";
readonly source_text="
pub usingnamespace if (@hasDecl(@import(\"@build\"), \"buildMain\"))
    @import(\"./zig_lib/build_runner.zig\")
else
    @import(\"./std_build_runner.zig\");
";
fn () 
{
    if test -L "$zig_lib_dir_link"; then
        if test "$zig_lib_dir" -ef $(realpath "$zig_lib_dir_link"); then
            if test -f "$std_build_runner_to"; then
                echo "install:";
                echo "zl:  ${zig_lib_dir/#$HOME/'~'}";
                echo "std: ${zig_install_lib_dir/#$HOME/'~'}";
                return 0;
            fi;
        else
            if test -x "$zig_lib_dir_link/support/uninstall.sh"; then
                if ! bash "$zig_lib_dir_link/support/uninstall.sh"; then 
                    return 2;
                fi;
            else 
                echo $error "unknown directory file system '$zig_lib_dir_link'";
                return 2;
            fi;
            if test -e "$zig_lib_dir_link"; then
                return 2;
            fi;
        fi;
    else
        if test -e "$zig_lib_dir_link"; then
            echo $error "'$zig_lib_dir_link' must be a link; is another kind of file";
            return 2;
        fi;
    fi;
    if ! ln -s "$zig_lib_dir" "$zig_lib_dir_link"; then
        return 2;
    fi;
    if test -f "$std_build_runner"; then
        if test -f "$std_build_runner_to"; then
            echo $error "destination path of standard library build runner already exists";
            return 2;
        else 
            if ! mv "$std_build_runner" "$std_build_runner_to"; then
                return 2;
            fi;
        fi;
    else
        echo $error "'$std_build_runner': no such file or directory; did nothing";
        return 2;
    fi;
    if ! test -e "$std_build_runner"; then
        if test -f "$std_build_runner_to"; then
            echo "$source_text" > "$std_build_runner";
        else
            echo $error "misplaced standard library build runner";
            return 2;
        fi;
        echo "installed:";
        echo "zl:  ${zig_lib_dir/#$HOME/'~'}";
        echo "std: ${zig_install_lib_dir/#$HOME/'~'}";
    fi;
}
fn;
