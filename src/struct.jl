StaticVector{N, T} = StrideArraysCore.StaticStrideArray{T, 1, (1,), Tuple{StaticInt{N}}, Tuple{Nothing}, Tuple{StaticInt{1}}, N} where {N, T}

const LVSIZE = 8192

const JAAddr = Tuple{UInt32, UInt16}
     
mutable struct JAPtr{T}
    obj::T
    addr::JAAddr
end

JAPtrVector{T} = StaticVector{LVSIZE, JAPtr{T}}

mutable struct Allocator{T}
    default::Function
    mem::Vector{JAPtrVector{T}}
    curr::Int64
    trash::Vector{JAAddr}
end