reference docs
- [rCore-Camp-Guide-2025S文档](https://learningos.cn/rCore-Camp-Guide-2025S)
- [A Freestanding Rust Binary](https://os.phil-opp.com/freestanding-rust-binary/)

reference code: https://github.com/misprit7/computerraria

requirements: 

```sh
rustup self update
rustup target add riscv32i-unknown-none-elf
rustup component add llvm-tools-preview
cargo install cargo-binutils
```