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
end

function length(::sample)::Int
    size(pd.dat,1)
end

function getCols(;pd::plasmaData,labels::Array{String})::Matrix{Float64}
    i = findall(in(labels).(pd.labels))
    pd.dat[:,i]
end