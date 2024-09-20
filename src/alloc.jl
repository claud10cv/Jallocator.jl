function allocator(::Type{T}, f::Function)::Allocator{T} where T
    alloc = Allocator{T}(f, JAPtrVector{T}[], 0, JAAddr[])
    return alloc
end

zeroPtr(alloc::Allocator{T}) where T = JAPtr{T}(alloc.f(), (0, 0))
zeroVector(alloc::Allocator{T}) where T = StrideArray(x -> zeroPtr(alloc), JAPtr{T}, StaticInt(LVSIZE))

function new_ptr!(alloc::Allocator{T})::JAPtr{T} where T
    if !isempty(alloc.trash)
        i, j = pop!(alloc.trash)
        return alloc.mem[i][j]
    end
    if alloc.curr == 0
        push!(alloc.mem, zeroVector(alloc))
        alloc.curr = 1
    end
    newlabelptr = alloc.mem[end][alloc.curr]
    newlabelptr.ptr = (length(alloc.mem), alloc.curr)
    alloc.curr = (alloc.curr + 1) % (LVSIZE + 1)
    return newlabelptr
end

function delete_ptr!(alloc::Allocator{T}, lptr::JAPtr{T})::Nothing where T
    push!(alloc.trash, lptr.ptr)
    return
end

function copy_ptr!(alloc::Allocator{T}, l::JAPtr{T})::JAPtr{T} where T
    return copy_ptr!(alloc, l.obj)
end

function copy_ptr!(alloc::Allocator{T}, l::T)::JAPtr{T} where T
    nlptr = new_ptr!(alloc)
    copy!(nlptr.obj, l)
    return nlptr
end

function Base.empty!(alloc::Allocator{T})::Allocator{T} where T
    if isempty(alloc.mem) 
        push!(alloc.mem, zeroVector(alloc)) 
    end
    while length(alloc.mem) > 1
        pop!(alloc.mem)
    end
    empty!(alloc.trash)
    alloc.curr = 1
    return alloc
end
