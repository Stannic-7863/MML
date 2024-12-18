# nativefiledialog-odin

[Odin](http://odin-lang.org/) bindings for the [Native File Dialog Extended](https://github.com/btzy/nativefiledialog-extended) library.

# Basic Usage
```odin
import nfd "./nativefiledialog"
import "core:fmt"

main :: proc() {
    nfd.Init()
    defer nfd.Quit()
    
    path: cstring
    filters := [2]nfd.Filter_Item { { "Source code", "c,cpp,cc" }, { "Headers", "h,hpp" } }
    args := nfd.Open_Dialog_Args {
        filter_list = raw_data(filters[:])
        filter_count = len(filters)
    }
    
    result := nfd.OpenDialogU8_With(&path, &args)
    switch result {
        case .Okay: {
            fmt.println("Success!")
            fmt.println(path)
            nfd.FreePathU8(path)
        }
        case .Cancel: fmt.println("User pressed cancel.")
        case .Error: fmt.println("Error:", nfd.GetError())
    }
}
```