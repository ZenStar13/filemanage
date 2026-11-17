fn main() {
    // The custom components draw nearly everything themselves; the std-widgets
    // style only affects the ListView scrollbar, so a dark built-in style fits.
    let config = slint_build::CompilerConfiguration::new().with_style("fluent-dark".into());
    slint_build::compile_with_config("ui/app.slint", config).expect("failed to compile Slint UI");
}
