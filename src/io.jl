function readFile(fname::AbstractString;instrument="Agilent")
    if instrument=="Agilent"
        sname, datetime, dat = readAgilent(fname)
        bwin = autoWindow(dat[:,2:end],blank=true)
        swin = autoWindow(dat[:,2:end],blank=false)
    else
        PTerror("unknownInstrument")
    end
    Sample(sname,datetime,dat,bwin,swin,"sample")
end

function load(dname::AbstractString;instrument="Agilent")
    fnames = readdir(dname)
    samples = Vector{Sample}(undef,0)
    datetimes = Vector{DateTime}(undef,0)
    ext = getExt(instrument)
    for fname in fnames
        if occursin(ext,fname)
            try
                pname = joinpath(dname,fname)
                samp = readFile(pname,instrument=instrument)
                push!(samples,samp)
                push!(datetimes,samp.datetime)
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
        samp.dat[:,1] = samp.dat[:,2]./sph .+ runtime[i]
    end
    return sortedsamples
end
export load

function readAgilent(fname::AbstractString,date_format="d/m/Y H:M:S")
    f = open(fname,"r")
    strs = readlines(f)

    # read header
    sname = split.(split(strs[1],"\\"),"/")[end][end]
    datetimestring = strs[3][findfirst(":",strs[3])[1]+2:
                             findfirst("using",strs[3])[1]-2]
    datetime = Dates.DateTime(datetimestring,
                              Dates.DateFormat(date_format))
    if Dates.Year(datetime) < Dates.Year(100)
        datetime += Dates.Year(2000)
    end
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

function getExt(instrument)
    if instrument == "Agilent"
        return ".csv"
    else
        PTerror("unknownInstrument")
    end
end
