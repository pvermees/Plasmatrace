function readFile(fname::AbstractString;
                  instrument::AbstractString="Agilent",
                  date_format::AbstractString,
                  head2name::Bool=false)
    if instrument=="Agilent"
        sname, datetime, dat = readAgilent(fname,date_format,head2name)
        bwin = autoWindow(dat[:,2:end],blank=true)
        swin = autoWindow(dat[:,2:end],blank=false)
    else
        PTerror("unknownInstrument")
    end
    Sample(sname,datetime,dat,bwin,swin,"sample")
end

function load(dname::AbstractString;
              instrument::AbstractString="Agilent",
              date_format::AbstractString="d/m/Y H:M:S",
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
                                date_format=date_format,
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

function readAgilent(fname::AbstractString,
                     date_format::AbstractString,
                     head2name::Bool=false)
    f = open(fname,"r")
    strs = readlines(f)
    nr = size(strs,1)
    
    # read header
    snamestring = head2name ? strs[1] : fname
    sname = split(snamestring,('\\','/'))[end]
    datetimeline = strs[3]
    from = findfirst(":",datetimeline)[1]+2
    to = findfirst("using",datetimeline)[1]-2
    datetime = Dates.DateTime(datetimeline[from:to],
                              Dates.DateFormat(date_format))
    if Dates.Year(datetime) < Dates.Year(100)
        datetime += Dates.Year(2000)
    end
    labels = split(strs[4],",")

    # read signals
    measurements = mapreduce(vcat, strs[5:(nr-3)]) do s
        (parse.(Float64, split(s, ",")))'
    end
    dat = DataFrame(measurements,labels)

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
