using Jallocator
using BenchmarkTools

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
    for _ in 1:n
        l = new_ptr!(alloc)
        push!(vec, l)
    end
    for _ in 1:n
        delete_ptr!(alloc, pop!(vec))
    end
    for _ in 1:n
        l = new_ptr!(alloc)
        push!(vec, l)
    end
end

function test_base(n)
    vec = MyStructPtr[]
    for _ in 1:n
        l = MyStructPtr()
        push!(vec, l)
    end
    for _ in 1:n
        pop!(vec)
    end
    for _ in 1:n
        l = MyStructPtr()
        push!(vec, l)
    end
end

alloc = allocator(MyStruct, () -> MyStruct())

@benchmark test_base(1000)
println("between tests")
@benchmark test_alloc(1000, alloc)