# zig-gobject

Bindings for GObject-based libraries (such as GTK) generated using GObject
introspection data.

## Usage

To use the bindings, find the [latest release of this
project](https://github.com/ianprime0509/zig-gobject/releases) and add the
desired bindings artifact as a dependency in `build.zig.zon`. Then, the exposed
bindings can be used as modules. For example:

```zig
const gobject = b.dependency("gobject", .{});
exe.root_module.addImport("gtk", gobject.module("gtk-4.0"));
exe.root_module.addImport("adw", gobject.module("adw-1"));
```

## Examples

There are several examples in the `example` directory, which is itself a
runnable project (depending on the `bindings` directory as a dependency). After
generating the bindings, the examples can be run using `zig build run` in the
`example` directory.

## Development environment

The bindings generated by this project cover a wide variety of libraries, and it
can be annoying and inconvenient to install these libraries on a host system for
testing purposes. The best way to get a consistent environment for testing is to
use [Flatpak](https://flatpak.org/):

1. Install `flatpak`.
2. Install the base SDK dependencies:
   - `flatpak install org.freedesktop.Sdk//23.08`
   - `flatpak install org.gnome.Sdk//45`
3. Install the Zig master extension for the Freedesktop SDK. This is not (yet)
   available on Flathub, so it must be built and installed manually.
   1. Install `flatpak-builder`.
   2. Clone
      https://github.com/ianprime0509/org.freedesktop.Sdk.Extension.ziglang-master
      and use the branch corresponding to the Freedesktop SDK installed above.
   3. Inside the clone, run `flatpak-builder --user --install build-dir org.freedesktop.Sdk.Extension.ziglang-master.yml`.

The steps above only need to be done once per GNOME SDK version. To enter a
development environment:

1. Run `flatpak run --filesystem=home --share=network --share=ipc --socket=fallback-x11 --socket=wayland --device=dri --socket=session-bus org.gnome.Sdk//44`
   - `--filesystem=home` - makes the user's home directory available within the
     container
   - `--share=network` - allows network access (needed to fetch `build.zig.zon`
     dependencies)
   - `--share=ipc --socket=fallback-x11 --socket=wayland --device=dri` - allows
     graphical display through X11 or Wayland
  - `--socket=session-bus` - allows access to the session bus
2. Within the spawned shell, run `. /usr/lib/sdk/ziglang-master/enable.sh` to
   add Zig to your `PATH` (don't forget the `.` at the beginning of that
   command).

## Running the binding generator

Running the binding generator requires GIR files to process. The easiest way to
get the full set of required GIR files is to set up a Flatpak development
environment as described in the previous section. Otherwise, a custom set of
bindings can be built by running the `zig-gobject` binary directly.

The command `zig build codegen -Dgir-profile=profile` can be used to generate
bindings for a predefined set of GIR files expected to be present at the path
specified by `-Dgir-files-path`, or `/usr/share/gir-1.0` if not specified. The
currently supported profiles are `gnome44` and `gnome45`, with the default being
`gnome45`. This will generate bindings to the `bindings` directory (within the
build output prefix, `zig-out` by default), which can be used as a dependency
(using the Zig package manager) in other projects.

If more control is needed over the source GIR files, `zig build` can be used to
build the `zig-gobject` binding generator executable, and it can be run directly
with any set of GIR input files and options.

## Further reading

- [Binding strategy](./doc/binding-strategy.md)

## License

This project is released under the [Zero-Clause BSD
License](https://spdx.org/licenses/0BSD.html). The libraries exposed by the
generated bindings are subject to their own licenses.
