abstract type plasmaData end

# immutable raw data, is used inside type 'sample'
struct SAMPLE <: plasmaData
    sname::String
    datetime::DateTime
    labels::Vector{String}
    dat::Matrix
end

# immutable raw collection of data, is used inside type 'run'
struct RUN <: plasmaData
    snames::Vector{String}
    datetimes::Vector{DateTime}
    labels::Vector{String}
    dat::Matrix
    index::Vector{Integer}
end

mutable struct window
    first::Integer
    last::Integer
end

# mutable extension of SAMPLE with blank and signal windows
mutable struct sample
    data::SAMPLE
    blank::Union{Nothing,Vector{window}}
    signal::Union{Nothing,Vector{window}}
    par::Union{Nothing,Vector}
    cov::Union{Nothing,Matrix}
end

# mutable extension of RUN with blank and signal window collections
mutable struct run
    data::RUN
    blanks::Vector{Union{Nothing,Vector{window}}}
    signals::Vector{Union{Nothing,Vector{window}}}
    par::Union{Nothing,Vector}
    cov::Union{Nothing,Matrix}
end

length(pd::RUN) = Base.length(pd.snames)
length(pd::run) = length(pd.data)

sample(pd::SAMPLE) = sample(pd,nothing,nothing,nothing,nothing)

run(pd::RUN) = run(pd,
                   fill(nothing,length(pd)),
                   fill(nothing,length(pd)),
                   nothing,nothing)

# convert an array of SAMPLEs to a RUN
function SAMPLES2RUN(SAMPLES::Vector{SAMPLE})::RUN

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
    dats = Vector{Matrix}(undef,ns)
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
function RUN2SAMPLE(pd::RUN;i::Int=1)::SAMPLE
    
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

function getCols(pd::plasmaData;labels::Vector{String})::Matrix
    
    i = findall(in(labels).(pd.labels))
    pd.dat[:,i]
    
end
