extern crate winres;

fn main() {
    if cfg!(target_os = "windows") {
        let res = winres::WindowsResource::new();

        //res.set_icon("img/logo/ruvname.ico");

        res.compile().unwrap();
    }
}
