@require "github.com/jkroso/Prospects.jl" need assoc push assoc_in
@require "github.com/jkroso/Port.jl" Port

"""
Cursors present immutable data as if it was mutable. But instead of mutating
the data it derives a new value and `put!`s it on a `Port`. Subscribing to
the `Port` provides access to all values in time series
"""
abstract Cursor

immutable TopLevelCursor <: Cursor
  value::Nullable
  port::Port
end

immutable SubCursor <: Cursor
  parent::Cursor
  key::Any
  value::Nullable
end

(::Type{Cursor})(value) = TopLevelCursor(value, Port())

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

need(c::Cursor) = need(c.value)

assoc!(c::Cursor, key, value) = put!(c, assoc(need(c), key, value))
assoc_in!(c::Cursor, pairs) = put!(c, assoc_in(need(c), pairs...))
