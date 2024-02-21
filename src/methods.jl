function getChannels(run::Vector{Sample})
    return getChannels(run[1])
end
function getChannels(samp::Sample)
    return names(samp.dat)[3:end]
end
function getChannels(pairing::Pairing)
    return collect(values(pairing.pairs))
end
export getChannels

function getSnames(run::Vector{Sample})
    ns = length(run)
    snames = Vector{String}(undef,ns)
    for i in eachindex(run)
        snames[i] = run[i].sname
    end
    return snames
end
export getSnames
