export readgraph, readdemands

function readgraph(filepath::String)
    open(filepath, "r") do f
        global dicttxt
        dicttxt = read(f)  # file information to string
    end

    json3str = JSON3.read(dicttxt, jsonlines=true)
    json3table = jsontable(json3str)
    json3df = DataFrame(json3table)
    gr_nodes = DataFrame(jsontable(json3df[1,:nodes]))
    gr_links = DataFrame(jsontable(json3df[1,:links]))
    gr_n = select(gr_nodes, [:stop_name, :node_id, :x, :y])
    gr_l = select(gr_links, [:node_id_1, :node_id_2, :distance, :traffic])
    gr_d = DataFrame(jsontable(json3df[1,:demands]))

    gr = MetaDiGraph()

    for (i, row) in enumerate( eachrow( gr_n ) )
        @assert add_vertex!(gr)
        set_prop!(gr, i, :name, row["stop_name"])
        set_prop!(gr, i, :id, row["node_id"])
        set_prop!(gr, i, :xcoord, row["x"])
        set_prop!(gr, i, :ycoord, row["y"])
    end
    set_indexing_prop!(gr, :name)

    for (i, row) in enumerate( eachrow( gr_l ) )
        @assert add_edge!(gr, gr[row["node_name_1"], :name], gr[row["node_name_2"], :name])
        @assert add_edge!(gr, gr[row["node_name_2"], :name], gr[row["node_name_1"], :name])
        set_prop!(gr, gr[row["node_name_1"], :name], gr[row["node_name_2"], :name], :length, row["distance"])
        set_prop!(gr, gr[row["node_name_2"], :name], gr[row["node_name_1"], :name], :length, row["distance"])
    end

    weightfield!(gr, :length)

    for (i, row) in enumerate( eachrow( gr_d ) )
        demandvalue = parse(Float64, row["demandValue"])
        set_prop!(gr, gr[row["source"], :name], gr[row["target"], :name], :demand, demandvalue)    
    end

    return gr
end

function readdemands(filepath::String; scale=1)
    open(filepath, "r") do f
        global dicttxt
        dicttxt = read(f)  # file information to string
    end

    json3str = JSON3.read(dicttxt, jsonlines=true)
    json3table = jsontable(json3str)
    json3df = DataFrame(json3table)
    gr_demands = DataFrame(jsontable(json3df[1,:demands]))

    ds = Dict{Tuple{String, String}, Float64}()
    for (i, row) in enumerate( eachrow( gr_demands ) )
        demandvalue = parse(Float64, row["demandValue"])
        demandsource = row["source"]
        demandtarget = row["target"]
        demandvalue = demandvalue
        ds[(demandsource, demandtarget)] = demandvalue * scale
    end

    return ds
end