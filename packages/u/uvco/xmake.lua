package("uvco")
    set_homepage("https://github.com/dermesser/uvco")
    set_description("C++20 Coroutines running on libuv for intuitive async I/O")
    set_license("GNU LGPL 2.1")

    add_urls("https://github.com/dermesser/uvco.git")
    add_versions("2026.3.30", "dd52da097f34a362486a64db4955d770b021ad9d")

    -- 可选功能开关
    add_configs("curl",     {description = "Enable curl integration",     default = false, type = "boolean"})
    add_configs("pqxx",     {description = "Enable libpqxx integration",  default = false, type = "boolean"})
    add_configs("examples", {description = "Build example http server lib", default = false, type = "boolean"})

    -- 核心依赖
    add_deps("cmake")
    add_deps("libuv")
    add_deps("fmt 9.x")
    -- 关键：必须显式声明 boost 组件，否则不会编译 log/log_setup/program_options
    add_deps("boost", {configs = {
        log = true,              -- 对应 boost_log
        program_options = true,  -- 对应 boost_program_options
        thread = true,           -- boost.log 依赖 thread
        filesystem = true,        -- 默认已开，保险起见
        asio = true,  
        serialization = true            
    }})

    -- 可选依赖：只在开启配置时才引入
    add_deps("curl", {configs = {ssl = true}, optional = true})
    add_deps("libpqxx", {optional = true})

    on_load(function (package)
        -- uvco 要求 C++23，这里标记一下供后续 on_test 使用
        package:data_set("cxx_standard", "c++23")
    end)

    on_install("!wasm", function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))

        -- 强制关闭 CMakeLists 里默认的 ASAN/Coverage/LTO，由 xmake 统一控制
        table.insert(configs, "-DENABLE_ASAN=0")
        table.insert(configs, "-DENABLE_COVERAGE=0")
        table.insert(configs, "-DENABLE_LTO=0")


        import("package.tools.cmake").install(package, configs, {packagedeps = {"boost", "libuv", "fmt"}})
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <uvco/run.h>
            #include <uvco/stream.h>

            using namespace uvco;

            void test() {
                runMain<void>([](const Loop &loop) -> Promise<void> {
                    auto stdout = TtyStream::stdout(loop);
                    co_await stdout.write("Hello World\n");
                    });
            }
        ]]}, {configs = {languages = "c++23"}, includes = {
            "uvco/run.h",
            "uvco/stream.h"
        }}))
    end)