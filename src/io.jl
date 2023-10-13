function readFile(;fname::String)::sample
    
    f = open(fname,"r")
    strs = readlines(f)

    # read header
    sname = strs[1]
    dt = split(strs[3]," ")
    date = parse.(Int,split(dt[8],"/"))
    time = parse.(Int,split(dt[9],":"))
    datetime = Dates.DateTime(2000+date[3],date[2],date[1],time[1],time[2],time[3])
    labels = split(strs[4],",")

    nr = size(strs)[1]-8

    dat = mapreduce(vcat, strs[5:(nr+4)]) do s
            (parse.(Float64, split(s, ",")))'
    end

    close(f)

    sample(sname,datetime,labels,dat)

end

function readFiles(;dname::String,ext::String=".csv")::Array{sample}

    fnames = readdir(dname)
    samps = []

    for fname in fnames
        if occursin(ext,fname)
            samp = readFile(fname=dname*fname)
            samps = push!(samps,samp)
        end
    end

    samps

end

function run(samples::Array{sample})::run

    ns = size(samples,1)

    datetimes = Array{DateTime}(undef,ns)
    for i in eachindex(datetimes)
        datetimes[i] = samples[i].datetime
    end
    order = sortperm(datetimes)
    dt = datetimes .- datetimes[order[1]]
    cumsec = Dates.value.(dt)./1000

    snames = Array{String}(undef,ns)
    labels = cat("cumtime",samples[1].labels,dims=1)
    dats = Array{Matrix{Float64}}(undef,ns)
    index = fill(1,ns)
    nr = 0

    for i in eachindex(samples)
        o = order[i]
        dats[i] = samples[o].dat
        if (i>1) index[i] = index[i-1] + nr end
        snames[i] = samples[o].sname
        cumtime = dats[i][1:end,1] .+ cumsec[o]
        dats[i] = hcat(cumtime,samples[o].dat)
        nr = size(dats[i],1)
    end

    bigdat = reduce(vcat,dats)

    run(snames,datetimes,labels,bigdat,index)

end
