StaticVector{N, T} = StrideArraysCore.StaticStrideArray{T, 1, (1,), Tuple{StaticInt{N}}, Tuple{Nothing}, Tuple{StaticInt{1}}, N} where {N, T}

const LVSIZE = 8192

mutable struct JAPtr{T}
    obj::T
    ptr::Tuple{Int64, Int64}
end

JAPtrVector{T} = StaticVector{LVSIZE, JAPtr{T}}

mutable struct Allocator{T}
    f::Function
    mem::Vector{JAPtrVector{T}}
    curr::Int64
    trash::Vector{Tuple{Int64, Int64}}
end