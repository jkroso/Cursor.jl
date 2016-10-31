@require "github.com/jkroso/Prospects.jl" exports...
@require "github.com/jkroso/Port.jl" Port

"""
Cursors present immutable data as if it was mutable. But instead of mutating
the data it derives a new value and `put!`s it on a `Port`. Subscribing to
the `Port` provides access to all values in time series
"""
abstract Cursor{T}

immutable TopLevelCursor{T} <: Cursor{T}
  value::Nullable{T}
  port::Port
end

immutable SubCursor{T} <: Cursor{T}
  parent::Cursor
  key::Any
  value::Nullable{T}
end

(::Type{Cursor})(value,port=Port()) = TopLevelCursor(value, port)
TopLevelCursor{T}(value::T, p::Port) = TopLevelCursor{T}(value, p)
SubCursor{T}(parent::Cursor, key::Any, value::T) = SubCursor{T}(parent, key, value)

Base.isnull(c::Cursor) = isnull(c.value)
Base.getindex(c::Cursor, key::Any) = get(c, key)
Base.get(c::Cursor, key, default=Nullable()) =
  SubCursor(c, key, isnull(c) ? c.value : get(need(c), key, default))

Base.put!(c::SubCursor, value) = (t=assoc(need(c.parent), c.key, value); put!(c.parent, t); t)
Base.put!(c::TopLevelCursor, value) = (put!(c.port, TopLevelCursor(value, c.port)); value)

Base.setindex!(c::Cursor, value, key) = assoc!(c, key, value)

Base.map(f::Function, c::Cursor) = map(t->f(SubCursor(c, t...)), enumerate(need(c)))

Base.map!(f::Function, c::Cursor) = put!(c, map(f, need(c)))
Base.push!(c::Cursor, value) = put!(c, push(need(c), value))
Base.append!(c::Cursor, value) = put!(c, append(need(c), value))
Base.:!(c::Cursor) = !need(c)

Base.eltype(c::Cursor) = SubCursor{eltype(need(c))}
Base.endof(c::Cursor) = endof(need(c))
Base.length(c::Cursor) = length(need(c))
Base.start(::Cursor) = 1
Base.next(c::Cursor, i) = (c[i], i + 1)
Base.done(c::Cursor, i) = i > endof(c)

need(c::Cursor) = need(c.value)

assoc!(c::Cursor, key, value) = put!(c, assoc(need(c), key, value))
assoc_in!(c::Cursor, pairs...) = put!(c, assoc_in(need(c), pairs...))

Base.delete!(c::SubCursor) = delete!(c.parent, c.key)
Base.delete!(c::Cursor, key) = put!(c, dissoc(need(c), key))
