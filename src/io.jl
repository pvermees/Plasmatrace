function readFile(fname::T;instrument="Agilent")::sample where T<:AbstractString
    if instrument=="Agilent"
        sname, datetime, dat = readAgilent(fname)
    else
        PTerror("unknownInstrument")
    end
    sample(sname,datetime,dat)
end

function load!(pd::run;dname::T,instrument="Agilent") where T<:AbstractString
    temp = load(dname,instrument=instrument)
    setSamples!(pd,getSamples(temp))
end
export load!

function load(dname::T;instrument="Agilent")::run where T<:AbstractString
    fnames = readdir(dname)
    samples = Vector{sample}(undef,0)
    datetimes = Vector{DateTime}(undef,0)
    ext = getExt(instrument)
    for fname in fnames
        if occursin(ext,fname)
            try
                pname = joinpath(dname,fname)
                samp = readFile(pname,instrument=instrument)
                push!(samples,samp)
                push!(datetimes,getDateTime(samp))
            catch e
                println("Failed to read "*fname)
            end
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
        setDat!(samp,dat)
    end
    out = run(sortedsamples)
    setInstrument!(out,instrument)
    out
end
export load

function readAgilent(fname::T) where T<:AbstractString
    f = open(fname,"r")
    strs = readlines(f)

    # read header
    sname = split.(split(strs[1],"\\"),"/")[end][end]
    dt = split(strs[3]," ")
    date = parse.(Int,split(dt[8],"/"))
    time = parse.(Int,split(dt[9],":"))
    datetime = Dates.DateTime(date[3],date[2],date[1],
                              time[1],time[2],time[3])
    labels = split(strs[4],",")

    # read signals
    nr = size(strs,1)
    measurements = mapreduce(vcat, strs[5:(nr-3)]) do s
        (parse.(Float64, split(s, ",")))'
    end
    labels = ["Run Time [hours]";labels]
    dat = DataFrame(hcat(measurements[:,1]./sph,measurements),labels)

    close(f)
    return sname, datetime, dat
end
