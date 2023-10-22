# Currently only works for Agilent files
function readFile(fname::String)::sample
    
    f = open(fname,"r")
    strs = readlines(f)

    # read header
    sname = strs[1]
    dt = split(strs[3]," ")
    date = parse.(Int,split(dt[8],"/"))
    time = parse.(Int,split(dt[9],":"))
    datetime = Dates.DateTime(date[3],date[2],date[1],
                              time[1],time[2],time[3])
    labels = split(strs[4],",")

    # read signals
    nr = size(strs,1)
    dat = mapreduce(vcat, strs[5:(nr-3)]) do s
        (parse.(Float64, split(s, ",")))'
    end

    labels = ["Run Time [hours]";labels]
    dat = hcat(dat[:,1]./sph,dat)

    close(f)

    sample(sname,datetime,labels,dat)

end

function load(dname::String;ext::String=".csv")::run

    fnames = readdir(dname)
    samples = Vector{sample}(undef,0)
    datetimes = Vector{DateTime}(undef,0)

    for fname in fnames
        if occursin(ext,fname)
            samp = readFile(dname*fname)
            push!(samples,samp)
            push!(datetimes,getDateTime(samp))
        end
    end

    order = sortperm(datetimes)
    sortedsamples = samples[order]
    sorteddatetimes = datetimes[order]
    
    dt = sorteddatetimes .- sorteddatetimes[1]
    runtime = Dates.value.(dt)./sph

    for i in eachindex(sortedsamples)
        samp = sortedsamples[i]
        dat = getDat(samp)
        dat[:,1] = dat[:,2]./sph .+ runtime[i]
        setDat!(samp;dat=dat)
    end

    run(sortedsamples)
    
end
