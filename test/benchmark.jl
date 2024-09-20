using Jallocator
using BenchmarkTools
using Random

struct MyStruct
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
        if t > 0.1
            l = new_ptr!(alloc)
            push!(vec, l)
        elseif !isempty(vec)
            delete_ptr!(alloc, pop!(vec))
        end
    end
end

function test_base(n)
    vec = MyStructPtr[]
    rng = MersenneTwister(0)
    for _ in 1:n
        t = rand(rng)
        if t > 0.1
            l = MyStructPtr()
            push!(vec, l)
        elseif !isempty(vec)
            pop!(vec)
        end
    end
end

alloc = allocator(MyStruct, () -> MyStruct())

@benchmark test_base(1000)
@benchmark test_alloc(1000, alloc)