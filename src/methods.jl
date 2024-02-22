function getChannels(run::Vector{Sample})
    return getChannels(run[1])
end
function getChannels(samp::Sample)
    return names(samp.dat)[3:end]
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

function summarise(run::Vector{Sample},verbatim=true)
    ns = length(run)
    snames = getSnames(run)
    groups = fill("sample",ns)
    dates = fill(run[1].datetime,ns)
    for i in eachindex(run)
        groups[i] = run[i].group
        dates[i] = run[i].datetime
    end
    out = DataFrame(name=snames,date=dates,group=groups)
    if verbatim println(out) end
    return out
end
function summarize(run::Vector{Sample},verbatim=true)
    summarise(run,verbatim)
end
export summarise, summarize
