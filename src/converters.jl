function SAMPLES2RUN(SAMPLES::Vector{SAMPLE})::RUN

    ns = size(SAMPLES,1)

    datetimes = Vector{DateTime}(undef,ns)
    for i in eachindex(datetimes)
        datetimes[i] = SAMPLES[i].datetime
    end
    order = sortperm(datetimes)
    dt = datetimes .- datetimes[order[1]]
    runtime = Dates.value.(dt)./sph

    snames = Vector{String}(undef,ns)
    labels = SAMPLES[1].labels
    dats = Vector{Matrix}(undef,ns)
    index = fill(1,ns)
    nr = 0

    for i in eachindex(SAMPLES)
        o = order[i]
        dats[i] = SAMPLES[o].dat
        if (i>1) index[i] = index[i-1] + nr end
        snames[i] = SAMPLES[o].sname
        dats[i][:,1] = dats[i][:,2]./sph .+ runtime[o]
        nr = size(dats[i],1)
    end

    bigdat = reduce(vcat,dats)

    RUN(snames,datetimes,labels,bigdat,index)

end

function RUN2SAMPLE(pd::RUN;i=1)::SAMPLE
    
    ns = length(pd)
    nr = nsweeps(pd)
    sname = pd.sname[i]
    datetime = pd.datetime[i]
    first = pd.index[i]
    last = i==ns ? nr : pd.index[i+1]-1
    dat =  pd.dat[first:last,:]

    SAMPLE(sname,datetime,pd.labels,dat)
    
end

function run2sample(pd::run;i=1)::sample

    SAMP = RUN2SAMPLE(pd.data;i=i)
    out = sample(SAMP)
    out.blank = pd.blank[i]
    out.signal = pd.signal[i]
    out.par = pd.par
    out.cov = pd.cov
    out.channels = pd.channels
    out

end
