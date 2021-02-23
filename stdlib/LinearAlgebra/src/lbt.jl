## This file contains libblastrampoline-specific APIs

# Keep these in sync with `src/libblastrampoline_internal.h`
struct lbt_library_info_t
    libname::Cstring
    handle::Ptr{Cvoid}
    suffix::Cstring
    interface::Int32
    f2c::Int32
end
const LBT_INTERFACE_LP64    = 32
const LBT_INTERFACE_ILP64   = 64
const LBT_INTERFACE_UNKNOWN = -1
const LBT_INTERFACE_MAP = Dict(
    LBT_INTERFACE_LP64    => :lp64,
    LBT_INTERFACE_ILP64   => :ilp64,
    LBT_INTERFACE_UNKNOWN => :unknown,
)

const LBT_F2C_PLAIN         =  0
const LBT_F2C_REQUIRED      =  1
const LBT_F2C_UNKNOWN       = -1
const LBT_F2C_MAP = Dict(
    LBT_F2C_PLAIN    => :plain,
    LBT_F2C_REQUIRED => :required,
    LBT_F2C_UNKNOWN  => :unknown,
)

struct LBTLibraryInfo
    libname::String
    handle::Ptr{Cvoid}
    suffix::String
    interface::Symbol
    f2c::Symbol

    function LBTLibraryInfo(lib_info::lbt_library_info_t)
        return new(
            unsafe_string(lib_info.libname),
            lib_info.handle,
            unsafe_string(lib_info.suffix),
            LBT_INTERFACE_MAP[lib_info.interface],
            LBT_F2C_MAP[lib_info.f2c],
        )
    end
end

struct lbt_config_t
    loaded_libs::Ptr{Ptr{lbt_library_info_t}}
    build_flags::UInt32
end
const LBT_BUILDFLAGS_DEEPBINDLESS = 0x01
const LBT_BUILDFLAGS_F2C_CAPABLE  = 0x02
const LBT_BUILDFLAGS_MAP = Dict(
    LBT_BUILDFLAGS_DEEPBINDLESS => :deepbindless,
    LBT_BUILDFLAGS_F2C_CAPABLE => :f2c_capable,
)

struct LBTConfig
    loaded_libs::Vector{LBTLibraryInfo}
    build_flags::Vector{Symbol}

    function LBTConfig(config::lbt_config_t)
        # Decode OR'ed flags into a list of names
        build_flag_names = Symbol[]
        for (flag, name) in LBT_BUILDFLAGS_MAP
            if config.build_flags & flag != 0x00
                push!(build_flag_names, name)
            end
        end
        # Unpack library info structures
        libs = LBTLibraryInfo[]
        idx = 1
        lib_ptr = unsafe_load(config.loaded_libs, idx)
        while lib_ptr != C_NULL
            push!(libs, LBTLibraryInfo(unsafe_load(lib_ptr)))

            idx += 1
            lib_ptr = unsafe_load(config.loaded_libs, idx)
        end
        return new(
            libs,
            build_flag_names,
        )
    end
end

function lbt_get_config()
    config_ptr = ccall((:lbt_get_config, libblastrampoline), Ptr{lbt_config_t}, ())
    return LBTConfig(unsafe_load(config_ptr))
end

function lbt_get_num_threads()
    return ccall((:lbt_get_num_threads, libblastrampoline), Int32, ())
end

function lbt_set_num_threads(nthreads)
    return ccall((:lbt_set_num_threads, libblastrampoline), Cvoid, (Int32,), nthreads)
end

function lbt_forward(path; clear::Bool = false, verbose::Bool = false)
    ccall((:lbt_forward, libblastrampoline), Int32, (Cstring, Int32, Int32), path, clear ? 1 : 0, verbose ? 1 : 0)
end

function lbt_set_default_func(addr)
    return ccall((:lbt_set_default_func, libblastrampoline), Cvoid, (Ptr{Cvoid},), addr)
end

function lbt_get_default_func()
    return ccall((:lbt_get_default_func, libblastrampoline), Ptr{Cvoid}, ())
end

#=
Don't define footgun API

function lbt_get_forward(symbol_name, interface, f2c = LBT_F2C_PLAIN)
    return ccall((:lbt_get_forward, libblastrampoline), Ptr{Cvoid}, (Cstring, Int32, Int32), symbol_name, interface, f2c)
end

function lbt_set_forward(symbol_name, addr, interface, f2c = LBT_F2C_PLAIN; verbose::Bool = false)
    return ccall((:lbt_set_forward, libblastrampoline), Int32, (Cstring, Ptr{Cvoid}, Int32, Int32, Int32), symbol_name, addr, interface, f2c, verbose ? 1 : 0)
end
=#