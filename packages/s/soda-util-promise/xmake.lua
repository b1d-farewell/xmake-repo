package("soda-util-promise")
    set_homepage("https://github.com/b1d-farewell/soda-cpp-util-promise.git")
    set_description("The soda-util-promise package")

    add_urls("https://github.com/b1d-farewell/soda-cpp-util-promise.git")
    add_versions("1.0.0", "efb2f49ad636fe4b298cefb414d8a96eca09e556")

    on_install(function (package)
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        -- TODO check includes and interfaces
        -- assert(package:has_cfuncs("foo", {includes = "foo.h"})
    end)
