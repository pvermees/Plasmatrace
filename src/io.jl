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

function readAgilent(fname::AbstractString)
    
    # read header
    sname = nothing
    datetime = nothing
    i = 0
    for line in eachline(fname)
        i += 1
        if i==1
            sname = split.(split(line,"\\"),"/")[end][end]
        elseif i==3
            dt = split(line," ")
            date = parse.(Int,split(dt[8],"/"))
            time = parse.(Int,split(dt[9],":"))
            datetime = Dates.DateTime(date[3],date[2],date[1],
                                      time[1],time[2],time[3])
            break
        end
    end

    # read signals
    measurements = CSV.read(fname,DataFrame,header=4,footerskip=3)
    hours = DataFrame("Run Time [hours]" => measurements[:,1]./sph)
    dat = hcat(hours,measurements)

    return sname, datetime, dat
end

function getExt(instrument)
    if instrument == "Agilent"
        return ".csv"
    else
        PTerror("unknownInstrument")
    end
end
