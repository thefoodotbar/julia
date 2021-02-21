# This file is a part of Julia. License is MIT: https://julialang.org/license

using Test, Libdl, OpenBLAS_jll, LinearAlgebra

@testset "OpenBLAS_jll" begin
    @test dlsym(OpenBLAS_jll.libopenblas_handle, BLAS.@blasfunc(openblas_set_num_threads); throw_error=false) != nothing
end
