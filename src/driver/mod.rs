/// Doc comment
use kernel::pr_info;

pub(crate) fn hello() {
    pr_info!("------------------------\n");
    pr_info!("Starting RustExample!\n");
    pr_info!("------------------------\n");
}