abstract type plasmaData end

struct sample <: plasmaData
    sname::String
    datetime::DateTime
    labels::Array{String}
    dat::Array{Float64}
end

struct run <: plasmaData
    snames::Array{String}
    datetimes::Array{DateTime}
    labels::Array{String}
    dat::Array{Float64}
    index::Array{Int}
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

function length(::sample)::Int
    size(pd.dat,1)
end

function getCols(;pd::plasmaData,labels::Array{String})::Matrix{Float64}
    i = findall(in(labels).(pd.labels))
    pd.dat[:,i]
end
