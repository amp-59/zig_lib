_install () 
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
    local zl_build_runner="$(realpath "$support_dir/../build_runner.zig")";
    local zl_zig_build="$(realpath "$support_dir/../build.zig")";
    local source_text="pub usingnamespace if (@hasDecl(@import(\"@build\"), \"buildMain\"))
    @import(\"./zig_lib/build_runner.zig\")
else
    @import(\"./std_build_runner.zig\");
";
    local info_text="
pub const zl = @import(\"./zig_lib/zig_lib.zig\");

//! Example build program:
const build = zl.build;
const Node = build.GenericNode(.{});

pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    _ = allocator;
    _ = toplevel;
}
";
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
        echo "$info_text";
    fi
}
_install;

