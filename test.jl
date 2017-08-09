include("main.jl")

c = Cursor(Dict(:a=>1,:b=>[:a,:b,:c]))

f = @spawn take!(c.port)
sleep(0)
put!(c[:b][2], :d)
@test need(need(f)) == Dict(:a=>1,:b=>[:a,:d,:c])

f = @spawn take!(c.port)
sleep(0)
c[:a] = 2
@test need(need(f)) == Dict(:a=>2,:b=>[:a,:b,:c])

c = Cursor([:a,:b])
@test map(identity, c) == [SubCursor(c,1,:a),SubCursor(c,2,:b)]
@test collect(c) == [SubCursor(c,1,:a),SubCursor(c,2,:b)]

c = Cursor([1,2,3])
f = @spawn take!(c.port)
sleep(0)
delete!(c[2])
@test need(f)|>need == [1,3]
