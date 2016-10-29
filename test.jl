include("main.jl")

c = Cursor(Dict(:a=>1,:b=>[:a,:b,:c]))
f = @spawn take!(c.port)
sleep(0)
put!(c[:b][2], :d)
@test need(need(f)) == Dict(:a=>1,:b=>[:a,:d,:c])
f = @spawn take!(c.port)
sleep(0)
assoc!(c,:a, 2)
@test need(need(f)) == Dict(:a=>2,:b=>[:a,:b,:c])
f = @spawn take!(c.port)
sleep(0)
c[:a] = 2
@test need(need(f)) == Dict(:a=>2,:b=>[:a,:b,:c])

c = Cursor([:a,:b])
@test map(identity, c) == [SubCursor(c,1,:a),SubCursor(c,2,:b)]

f = @spawn take!(c.port)
sleep(0)
map!(string, c)
@test need(need(f)) == ["a", "b"]

f = @spawn take!(c.port)
sleep(0)
push!(c, :c)
@test need(need(f)) == [:a, :b, :c]
