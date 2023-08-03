_uninstall () 
{ 
    hash zig;
    local error="error:";
    local warn="warn: ";
    local blank="      ";
    local script_realpath="$(realpath "$0")";
    local support_dir="$(dirname "$script_realpath")";
    local zig_exe="$(hash -t zig)";
    local zig_real_exe="$(realpath "$zig_exe")";
    local zig_install_lib_dir="$(dirname "$zig_real_exe")/lib";
    local zig_lib_dir="$(dirname "$support_dir")";
    local zig_lib_dir_link="$zig_install_lib_dir/zig_lib";
    local std_build_runner="$zig_install_lib_dir/build_runner.zig";
    local std_build_runner_to="$zig_install_lib_dir/std_build_runner.zig";
    if test -L "$zig_lib_dir_link"; then
        if test "$zig_lib_dir" -ef "$(realpath "$zig_lib_dir_link")"; then
            if ! unlink "$zig_lib_dir_link"; then
                return 2;
            fi;
        else
            if test -d "$zig_lib_dir_link"; then
                if test -f "$zig_lib_dir_link/support/uninstall.sh"; then
                    exec bash "$zig_lib_dir_link/support/uninstall.sh";
                else
                    echo $error "unknown directory file system '$zig_lib_dir_link'";
                    return 2;
                fi;
            else
                echo $error "unknown file system '$zig_lib_dir_link'";
                return 2;
            fi;
        fi;
    fi;
    if test -f "$std_build_runner_to"; then
        if ! mv "$std_build_runner_to" "$std_build_runner"; then
            return 2;
        fi;
        echo "uninstalled:";
        echo "zl:  ${zig_lib_dir/#$HOME/'~'}";
        echo "std: ${zig_install_lib_dir/#$HOME/'~'}";
        return 0;
    fi
}
_uninstall;
