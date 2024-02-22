function getChannels(run::Vector{Sample})
    return getChannels(run[1])
end
function getChannels(samp::Sample)
    return names(samp.dat)[3:end]
end
export getChannels

function getSnames(run::Vector{Sample})
    return getAttr(run,:sname)
end
export getSnames
function getGroups(run::Vector{Sample})
    return getAttr(run,:group)
end
export getGroups
function getAttr(run::Vector{Sample},attr::Symbol)
    ns = length(run)
    first = getproperty(run[1],attr)
    out = fill(first,ns)
    for i in eachindex(run)
        out[i] = getproperty(run[i],attr)
    end
    return out
end

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
