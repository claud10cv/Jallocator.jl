module Jallocator
    using StrideArrays, StrideArraysCore
    import Base.empty!
    import Base.==
    include("struct.jl")
    include("alloc.jl")
    export allocator, new_ptr!, delete_ptr!, copy_ptr!, empty!, nulladdr, isnull, get_object, get_address, get_pointer, zeroPtr
    export JAPtr, JAAddr, Allocator
end # module Jallocator
