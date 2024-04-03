function load(dname::AbstractString;
              instrument::AbstractString="Agilent",
              head2name::Bool=false)
    fnames = readdir(dname)
    samples = Vector{Sample}(undef,0)
    datetimes = Vector{DateTime}(undef,0)
    ext = getExt(instrument)
    maxT = 0.0
    for fname in fnames
        if occursin(ext,fname)
            try
                pname = joinpath(dname,fname)
                samp = readFile(pname,
                                instrument=instrument,
                                head2name=head2name)
                push!(samples,samp)
                push!(datetimes,samp.datetime)
                maxT = maximum([maxT,maximum(samp.dat[:,1])])
            catch e
                println("Failed to read "*fname)
            end
        end
    end
    order = sortperm(datetimes)
    sortedsamples = samples[order]
    sorteddatetimes = datetimes[order]
    dt = sorteddatetimes .- sorteddatetimes[1]
    runtime = Dates.value.(dt)
    maxt = runtime[end] + maxT
    for i in eachindex(sortedsamples)
        samp = sortedsamples[i]
        samp.dat.t = (samp.dat[:,1] .+ runtime[i])./maxt
        samp.dat.T = samp.dat[:,1] ./ maxT
    end
    return sortedsamples
end
export load

function readFile(fname::AbstractString;
                  instrument::AbstractString="Agilent",
                  head2name::Bool=false)
    if instrument=="Agilent"
        sname, datetime, labels, datalines =
            readAgilent(fname,head2name)
    elseif instrument=="ThermoFisher"
        sname, datetime, labels, datalines =
            readThermoFisher(fname,head2name)
    else
        PTerror("unknownInstrument")
    end
    measurements = mapreduce(vcat, datalines) do s
        (parse.(Float64, split(s, ",")))'
    end
    dat = DataFrame(measurements,labels)
    bwin = autoWindow(dat[:,2:end],blank=true)
    swin = autoWindow(dat[:,2:end],blank=false)
    return Sample(sname,datetime,dat,bwin,swin,"sample")
end

function readAgilent(fname::AbstractString,
                     head2name::Bool=false)
    
    f = open(fname,"r")
    lines = readlines(f)
    close(f)
    snamestring = head2name ? lines[1] : fname
    sname = split(snamestring,r"[\\/.]")[end-1]
    datetimeline = lines[3]
    from = findfirst(":",datetimeline)[1]+2
    to = findfirst("using",datetimeline)[1]-2
    datetime = automatic_datetime(datetimeline[from:to])
    labels = split(lines[4],",")
    datalines = lines[5:end-3]

    return sname, datetime, labels, datalines
    
end

function readThermoFisher(fname::AbstractString,
                          head2name::Bool=false)
    f = open(fname,"r")
    lines = readlines(f)
    close(f)
    snamestring = head2name ? split(lines[1],":")[1] : fname
    sname = split(snamestring,r"[\\/.]")[end-1]
    datetimeline = lines[1]
    from = findfirst(":",datetimeline)[1]+1
    to = findfirst(";",datetimeline)[1]-1
    datetime = automatic_datetime(datetimeline[from:to])
    labels = split(lines[14],",")
    datalines = lines[16:end]

    return sname, datetime, labels, datalines
    
end
