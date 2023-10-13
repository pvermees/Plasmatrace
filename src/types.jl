abstract type plasmaData end
abstract type hasBlank <: plasmaData end
abstract type hasFract <: hasBlank end

struct sample <: plasmaData
    sname::String
    datetime::DateTime
    labels::Vector{String}
    dat::Matrix{Float64}
end

struct run <: plasmaData
    snames::Vector{String}
    datetimes::Vector{DateTime}
    labels::Vector{String}
    dat::Matrix{Float64}
    index::Vector{Int}
end

mutable struct bsample <: hasBlank
    sname::String
    datetime::DateTime
    labels::Vector{String}
    dat::Matrix{Float64}
    blanks::Matrix{Float64}
end

mutable struct brun <: hasBlank
    snames::Vector{String}
    datetimes::Vector{DateTime}
    labels::Vector{String}
    dat::Matrix{Float64}
    index::Vector{Int}
    blanks::Vector{Matrix{Float64}}
end

function samples2run(;samples::Vector{sample})::run

    ns = size(samples,1)

    datetimes = Vector{DateTime}(undef,ns)
    for i in eachindex(datetimes)
        datetimes[i] = samples[i].datetime
    end
    order = sortperm(datetimes)
    dt = datetimes .- datetimes[order[1]]
    cumsec = Dates.value.(dt)./1000

    snames = Vector{String}(undef,ns)
    labels = cat("cumtime",samples[1].labels,dims=1)
    dats = Vector{Matrix{Float64}}(undef,ns)
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

function run2sample(;pd::run,i::Int=1)::sample
    
    ns = size(pd.snames,1)
    nr = size(pd.dat,1)
    sname = pd.snames[i]
    datetime = pd.datetimes[i]
    labels = pd.labels[2:end]
    first = pd.index[i]
    last = i==ns ? nr : pd.index[i+1]-1
    dat =  pd.dat[first:last,2:end]

    sample(sname,datetime,labels,dat)
    
end

function getCols(;pd::plasmaData,labels::Vector{String})::Matrix{Float64}
    i = findall(in(labels).(pd.labels))
    pd.dat[:,i]
end
