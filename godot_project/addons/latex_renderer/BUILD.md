# LaTeX Renderer Build

Run these commands from `addons/latex_renderer/rust`.

The `godot`/gdext Rust bridge used here requires Rust 1.94 or newer. If your default stable toolchain is older, install nightly and replace `cargo` with `cargo +nightly` in native commands.

## Native Desktop

```sh
cargo build
cp target/debug/liblatex_renderer.so ../bin/linux/liblatex_renderer.debug.x86_64.so

cargo build --release
cp target/release/liblatex_renderer.so ../bin/linux/liblatex_renderer.release.x86_64.so
```

Windows from a Windows Rust shell:

```bat
cargo build
copy target\debug\latex_renderer.dll ..\bin\windows\latex_renderer.debug.x86_64.dll

cargo build --release
copy target\release\latex_renderer.dll ..\bin\windows\latex_renderer.release.x86_64.dll
```

macOS, repeat for each target and copy the result matching the `.gdextension` paths:

```sh
rustup target add x86_64-apple-darwin aarch64-apple-darwin
cargo build --target x86_64-apple-darwin
cp target/x86_64-apple-darwin/debug/liblatex_renderer.dylib ../bin/macos/liblatex_renderer.debug.x86_64.dylib
cargo build --release --target x86_64-apple-darwin
cp target/x86_64-apple-darwin/release/liblatex_renderer.dylib ../bin/macos/liblatex_renderer.release.x86_64.dylib

cargo build --target aarch64-apple-darwin
cp target/aarch64-apple-darwin/debug/liblatex_renderer.dylib ../bin/macos/liblatex_renderer.debug.arm64.dylib
cargo build --release --target aarch64-apple-darwin
cp target/aarch64-apple-darwin/release/liblatex_renderer.dylib ../bin/macos/liblatex_renderer.release.arm64.dylib
```

## WebAssembly / Emscripten

Install the Rust and Emscripten toolchains:

```sh
rustup toolchain install nightly
rustup component add rust-src --toolchain nightly
rustup target add wasm32-unknown-emscripten --toolchain nightly

git clone https://github.com/emscripten-core/emsdk.git /tmp/emsdk
/tmp/emsdk/emsdk install 3.1.74
/tmp/emsdk/emsdk activate 3.1.74
source /tmp/emsdk/emsdk_env.sh
```

Build the threaded web side module:

```sh
RUSTFLAGS="-C link-args=-pthread \
-C target-feature=+atomics \
-C link-args=-sSIDE_MODULE=2 \
-C llvm-args=-enable-emscripten-cxx-exceptions=0 \
-Z default-visibility=hidden \
-Z link-native-libraries=no \
-Z emscripten-wasm-eh=false" \
cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten --features web

cp target/wasm32-unknown-emscripten/debug/latex_renderer.wasm ../bin/web/debug/latex_renderer.threads.wasm
```

Build the single-threaded fallback side module:

```sh
cargo +nightly build -Zbuild-std --target wasm32-unknown-emscripten --no-default-features --features nothreads
cp target/wasm32-unknown-emscripten/debug/latex_renderer.wasm ../bin/web/debug/latex_renderer.wasm
```

Release web builds use the same commands with `--release`, then copy from `target/wasm32-unknown-emscripten/release/` into `../bin/web/release/`.

In Godot's Web export preset, enable `Extensions Support`. Enable `Thread Support` only when exporting with the `.threads.wasm` build and serving with COOP/COEP headers. The `nothreads` build is selected automatically by Godot when the export runs without thread support.
