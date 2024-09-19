module Jallocator
    using StrideArrays, StrideArraysCore
    import Base.zero, Base.empty!
    include("struct.jl")
    include("alloc.jl")
    export allocator, new_ptr!, delete_ptr!, copy_ptr!, empty!
    export JAPtr
end # module Jallocator
