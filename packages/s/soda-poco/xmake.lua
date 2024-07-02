package("soda-poco")
    set_homepage("https://gitlab.corp.youdao.com/zhangyy31/poco.cross")
    add_urls("https://gitlab.corp.youdao.com/zhangyy31/poco.cross.git")
    add_configs("check", {
        description = "check on install",
        default = false,
        type = "boolean"
    })
    add_configs("jobs", {
        description = "build from sources with -j <jobs>",
        default = 2,
        type = "number"
    })
    add_configs("openssl", {
        description = "configure dependent openssl",
        default = {
            system = true,
            version = "1.1.1w"
            root = os.getenv("OPENSSL_ROOT_DIR")
        },
        type = "table"
    })
    add_configs("foundation", {
        description = "includes foundation component",
        default = true,
        type = "boolean"
    })
    add_configs("json", {
        description = "includes json component",
        default = true,
        type = "boolean"
    })
    add_configs("util", {
        description = "includes util component",
        default = true,
        type = "boolean"
    })
    add_configs("xml", {
        description = "includes xml component",
        default = true,
        type = "boolean"
    })
    add_configs("net", {
        description = "includes net component",
        default = true,
        type = "boolean"
    })
    on_load(function(pkg)
        local openssl = pkg:config("openssl")
        if openssl.system then 
            local pkg = find_package("openssl", {
                version = openssl.version
            })
            openssl.root = path.directory(openssl_pkg.includedirs[1])
        end

        -- in fact, components could be directly recognized by internal cmake module 
        -- but we only handle configure-make workflow for now
        for _, component in ipairs({"foundation", "json", "util", "xml", "net"}) do 
            if pkg:config(component) then 
                component, _ = component:gsub("^%l", string.upper)
                pkg:add("components", component) 
            end
        end
    end)

    on_fetch(function (pkg)
        local result = {
            links = {}
        }
        for component, _ in pairs(pkg:components()) do 
            table.insert(result.links, "Poco" .. component)
        end
        result.linkdirs = { package:installdir("lib") }
        result.includedirs = { package:installdir("include") }
        return result
    end)

    on_install("ohos|x86_64", "ohos|arm64", "macosx|x86_64" , function(pkg)
        local components = {}
        for component, _ in pairs(pkg:components()) do 
            table.insert(components, component)
        end
        local openssl_root <const> = pkg:get("openssl_root") 
        local sourcedir <const> = pkg:get("sourcedir")
        local install_dir <const> = pkg:get("install_dir")
        
        local build_config = nil 
        if  is_plat("ohos") then 
            build_config = "OHOS"
        elseif is_plat("macosx") then 
            build_config = "Darwin"
        end

        assert(build_config, "Failed to select build config")

        local build_dir = vformat("build-$(plat)-$(arch)-$(mode)")

        os.exec("mkdir -p " .. build_dir) 

        os.exec("chmod +x configure")
        os.cd(build_dir)

        local configure_cmd = vformat("../configure  --prefix=%s --mode=$(mode) --static --no-samples --no-tests --config=%s --openssl-root=%s --target-cpu=$(arch) --target-os=$(plat) --required=%s", pkg:installdir(), build_config, pkg:config("openssl").root, table.join(components, ","))

        if is_plat("ohos") then 
            local ohos_sdk_root <const> = get_config("ohos_sdk_root")
            configure_cmd = configure_cmd .. " --ohos-sdk-root=" .. ohos_sdk_root
        end

        local filename = "configure" 
        local file = io.open(filename, "w")
        assert(file, "Failed to create configure file: %s", filename)

        file:write("#!/bin/bash\n")
        file:write(configure_cmd)
        file:close()
        assert(os.exec("chmox +x " .. filename) == 0, "Failed to chmod +x %s", filename)
        assert(os.exec("./configure") == 0, "Failed to configure")

        assert(os.exec("make clean") == 0, "Failed to clean")
        assert(os.exec("make -j " .. pkg:config("jobs")) == 0, "Failed to compile")
        assert(os.exec("make install") == 0, "Failed to install")
    end)

    on_test(function(pkg)
        if pkg:config("check") then
            assert(package:has_cxxtypes("Poco::Timestamp", {includes = "Poco/Timestamp.h"}))

            assert(package:check_cxxsnippets([[
                #include <Poco/Timestamp.h>
                #include <iostream>
                using namespace Poco;
                int main() {
                    Timestamp now;
                    std::cout << "Timestamp: " << now.epochMicroseconds() << std::endl;
                    return 0;
                }
            ]], {configs = {languages = "c++11"}}))
        end
    end)
package_end()