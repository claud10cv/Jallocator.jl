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
We have 
```julia
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

@benchmark test_base(10000)

BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  135.024 μs …  19.042 ms  ┊ GC (min … max):  0.00% … 97.38%
 Time  (median):     152.798 μs               ┊ GC (median):     0.00%
 Time  (mean ± σ):   215.713 μs ± 393.637 μs  ┊ GC (mean ± σ):  13.46% ±  9.42%

  █▄▂▃▄▄▁  ▂▁                                                   ▁
  ███████▆████▄▁▃▁▁▃▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃▃▁▃▄▄▅ █
  135 μs        Histogram: log(frequency) by time       2.13 ms <

 Memory estimate: 561.25 KiB, allocs estimate: 8990.

@benchmark test_alloc(10000, alloc)

BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  130.720 μs …   8.204 ms  ┊ GC (min … max): 0.00% … 39.52%
 Time  (median):     147.744 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   155.248 μs ± 111.601 μs  ┊ GC (mean ± σ):  2.49% ±  4.63%

  ▃▄▂▂▂▁▁▇▇▅▅██▆▆▆▅▄▃▂▂▂▁▁                                      ▂
  ██████████████████████████▇▇▆▅▄▆▅▆▆▇▆▆▆▇██▇████▇▆▇▆▇▅▆▅▆▅▆▄▆▅ █
  131 μs        Histogram: log(frequency) by time        218 μs <

 Memory estimate: 141.44 KiB, allocs estimate: 34.

```
