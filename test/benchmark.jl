using Jallocator
using BenchmarkTools
using Random

mutable struct MyStruct
    x::Int64
    y::Char
end

const MyStructPtr = JAPtr{MyStruct}

import Base.copy!
import Base.zero

function Base.copy!(dst::MyStruct, src::MyStruct)
    dst.x = src.x
    dst.y = src.y
    return dst
end

MyStruct() = MyStruct(0, 'A')
MyStructPtr() = MyStructPtr(MyStruct(), (0, 0))

function test_alloc(n, alloc)
    empty!(alloc)
    vec = MyStructPtr[]
    rng = MersenneTwister(0)
    for _ in 1:n
        t = rand(rng)
        if t > 2//3
            push!(vec, new_ptr!(alloc))
        elseif t > 1//3
            delete_ptr!(alloc, new_ptr!(alloc))     
        elseif !isempty(vec)
            delete_ptr!(alloc, pop!(vec))
        end
    end
end

function test_base(n)
    vec = MyStruct[]
    rng = MersenneTwister(0)
    for _ in 1:n
        t = rand(rng)
        if t > 2//3
            push!(vec, MyStruct())
        elseif t > 1//3
            l = MyStruct()
        elseif !isempty(vec)
            pop!(vec)
        end
    end
end

alloc = allocator(MyStruct, () -> MyStruct())

@benchmark test_base(10000000)
@benchmark test_alloc(10000000, alloc)