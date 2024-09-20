# Jallocator.jl
An allocator in Julia for handling the dynamic creation of objects with minimal heap allocations

## Installation
From the Julia Pkg REPL simply execute
```julia
(@v1.11) pkg> add Jallocator
```

## Example of use
Assume that we want to create an allocator to store objects of the type `MyStruct`, defined as follows
```julia
struct MyStruct
    x::Int64
    y::Char
end
```
The allocator saves memory for thousands of objects at a time, with few allocations.

### Initialization
We must have defined a function that constructs an empty object, for instance as follows
```julia
MyStruct() = MyStruct(0, 'a')
```
Now, we can create an allocator for pointers of objects of our custom type
```julia
alloc = allocator(MyStruct, () -> MyStruct())
```
### Create a new object and return its pointer
To create a new object and return its pointer, we use the method `new_ptr!`
```julia
ptr = new_ptr!(alloc)
```
### Delete an object
To delete the pointer `ptr`, we use the method `delete_ptr!`
```julia
delete_ptr!(alloc, ptr)
```
### Accessing the object
To access the object itself for a given pointer `ptr`, we do
```julia
s = ptr.obj
```
It is also possible to get the pointer given its address, as follows
```julia
p = new_Label!(alloc)
q = get_pointer(alloc, p.addr)
p == q # returns true, they are the same object
```

### Copying an object
To create a copy of an object pointing to `ptr`, we first must make sure that `MyStruct` admits copying, for instance by declaring a copy function
```julia
import Base.copy!
function Base.copy!(dst::MyStruct, src::MyStruct)
    dst.x = src.x
    dst.y = src.y
end
```
Then, we can use the copy! function to copy pointers, as follows
```julia
ptr = new_ptr!(alloc)
obj = ptr.obj
copy_ptr!(alloc, ptr) # copying from a pointer 
copy_ptr!(alloc, obj) # copying from an object directly 
 ```
### Emptying the allocator
We can also empty the allocator, as follows
```julia
empty!(alloc)
```

## Benchmarking
The following benchmarks gives a hint about the performance of the data structures
```julia
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
            l = new_ptr!(alloc)
            push!(vec, l)
        elseif t > 1//3
            l = new_ptr!(alloc)
            delete_ptr!(alloc, l)     
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
        if t > 2//3
            l = MyStructPtr()
            push!(vec, l)
        elseif t > 1//3
            l = MyStructPtr()
        elseif !isempty(vec)
            pop!(vec)
        end
    end
end

alloc = allocator(MyStruct, () -> MyStruct())

julia> @benchmark test_base(10000000)

BenchmarkTools.Trial: 9 samples with 1 evaluation.
 Range (min … max):  555.411 ms … 746.736 ms  ┊ GC (min … max): 2.41% … 1.69%
 Time  (median):     568.007 ms               ┊ GC (median):    2.23%
 Time  (mean ± σ):   586.083 ms ±  60.641 ms  ┊ GC (mean ± σ):  1.89% ± 0.64%

  ▁█ ▁█▁▁                                                     ▁  
  ██▁████▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  555 ms           Histogram: frequency by time          747 ms <

 Memory estimate: 101.93 MiB, allocs estimate: 3335683.

julia> @benchmark test_alloc(10000000, alloc)

BenchmarkTools.Trial: 10 samples with 1 evaluation.
 Range (min … max):  491.019 ms … 544.360 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     501.598 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   508.871 ms ±  17.521 ms  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █   █  █ █ ██        █    █                      █          █  
  █▁▁▁█▁▁█▁█▁██▁▁▁▁▁▁▁▁█▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁█ ▁
  491 ms           Histogram: frequency by time          544 ms <

 Memory estimate: 141.44 KiB, allocs estimate: 34.
```
