abstract type plasmaData end

# immutable raw data, is used inside type 'sample'
struct SAMPLE <: plasmaData
    sname::String
    datetime::DateTime
    labels::Vector{String}
    dat::Matrix{Float64}
end

# immutable raw collection of data, is used inside type 'run'
struct RUN <: plasmaData
    snames::Vector{String}
    datetimes::Vector{DateTime}
    labels::Vector{String}
    dat::Matrix{Float64}
    index::Vector{Int}
end

# mutable extension of SAMPLE with blank and signal windows
mutable struct sample
    data::SAMPLE
    blank::Vector{Float64}
    signal::Vector{Float64}
end

# mutable extension of RUN with blank and signal window collections
mutable struct run
    data::RUN
    blanks::Vector{Vector{Float64}}
    signals::Vector{Vector{Float64}}
end

SAMPLE2sample(pd::SAMPLE) = sample(pd,[0,0],[0,0])

function RUN2run(pd::RUN)
    snames = pd.snames
    blanks = [zeros(2) for _ in eachindex(snames)]
    signals = [zeros(2) for _ in eachindex(snames)]
    run(pd,blanks,signals)
end

# convert an array of SAMPLEs to a RUN
function SAMPLES2RUN(;SAMPLES::Vector{SAMPLE})::RUN

    ns = size(SAMPLES,1)

    datetimes = Vector{DateTime}(undef,ns)
    for i in eachindex(datetimes)
        datetimes[i] = SAMPLES[i].datetime
    end
    order = sortperm(datetimes)
    dt = datetimes .- datetimes[order[1]]
    cumsec = Dates.value.(dt)./1000

    snames = Vector{String}(undef,ns)
    labels = cat("cumtime",SAMPLES[1].labels,dims=1)
    dats = Vector{Matrix{Float64}}(undef,ns)
    index = fill(1,ns)
    nr = 0

    for i in eachindex(SAMPLES)
        o = order[i]
        dats[i] = SAMPLES[o].dat
        if (i>1) index[i] = index[i-1] + nr end
        snames[i] = SAMPLES[o].sname
        cumtime = dats[i][1:end,1] .+ cumsec[o]
        dats[i] = hcat(cumtime,SAMPLES[o].dat)
        nr = size(dats[i],1)
    end

    bigdat = reduce(vcat,dats)

    RUN(snames,datetimes,labels,bigdat,index)

end

# extract a SAMPLE from a RUN
function RUN2SAMPLE(;pd::RUN,i::Int=1)::SAMPLE
    
    ns = size(pd.snames,1)
    nr = size(pd.dat,1)
    sname = pd.snames[i]
    datetime = pd.datetimes[i]
    labels = pd.labels[2:end]
    first = pd.index[i]
    last = i==ns ? nr : pd.index[i+1]-1
    dat =  pd.dat[first:last,2:end]

    SAMPLE(sname,datetime,labels,dat)
    
end

function getCols(;pd::plasmaData,labels::Vector{String})::Matrix{Float64}
    
    i = findall(in(labels).(pd.labels))
    pd.dat[:,i]
    
end
