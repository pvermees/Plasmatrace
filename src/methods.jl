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

function setStandards!(run::Vector{Sample},selection::Vector{Int},refmat::AbstractString)
    for i in selection
        run[i].group = refmat
    end
end
function setStandards!(run::Vector{Sample},prefix::AbstractString,refmat::AbstractString)
    snames = getSnames(run)
    selection = findall(contains(prefix),snames)
    setStandards!(run::Vector{Sample},selection,refmat)
end
function setStandards!(run::Vector{Sample},standards::Dict)
    for (refmat,prefix) in standards
        setStandards!(run,prefix,refmat)
    end
end
function setStandards!(run::Vector{Sample})
    for sample in run
        sample.group = "sample" # reset
    end
end
export setStandards!
function resetStandards!(run::Vector{Sample},selection::Vector{Int})
    for i in selection
        run[i].group = "sample"
    end
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

function getx0y0(method::AbstractString,refmat::AbstractString)
    L = lambda[method][1]
    t = referenceMaterials[method][refmat].t[1]
    x0 = 1/(exp(L*t)-1)
    y0 = referenceMaterials[method][refmat].y0[1]
    return (x0=x0, y0=y0)
end

function getAnchor(method::String,refmat::String)
    if method=="LuHf"
        return getx0y0(method,refmat)
    end
end
function getAnchor(method::AbstractString,standards::AbstractDict)
    nr = length(standards)
    out = Dict{String, NamedTuple}()
    for (refmat,prefix) in standards
        out[refmat] = getAnchor(method,refmat)
    end
    return out
end
export getAnchor

function setBwin!(samp::Sample,bwin=nothing)
    if isnothing(bwin) bwin=autoWindow(samp,blank=true) end
    samp.bwin = bwin
end
export setBwin!

function setSwin!(samp::Sample,swin=nothing)
    if isnothing(swin) swin=autoWindow(samp,blank=false) end
    samp.swin = swin
end
export setSwin!

function autoWindow(signals::AbstractDataFrame;blank=false)
    total = sum.(eachrow(signals))
    q = Statistics.quantile(total,[0.05,0.95])
    mid = (q[2]+q[1])/10
    low = total.<mid
    blk = findall(low)
    sig = findall(.!low)
    if blank
        min = minimum(blk)
        max = maximum(blk)
        from = floor(Int,min)
        to = floor(Int,(19*max+min)/20)
    else
        min = minimum(sig)
        max = maximum(sig)
        from = ceil(Int,(9*min+max)/10)
        to = ceil(Int,max)
    end
    return [(from,to)]
end
function autoWindow(samp::Sample;blank=false)
    autoWindow(samp.dat[:,3:end],blank=blank)
end

function pool(run::Vector{Sample};blank=false,signal=false,group=nothing)
    if isnothing(group)
        selection = 1:length(run)
    else
        groups = getGroups(run)
        selection = findall(contains(group),groups)
    end
    ns = length(selection)
    dats = Vector{DataFrame}(undef,ns)
    for i in eachindex(selection)
        dats[i] = windowData(run[selection[i]],blank=blank,signal=signal)
    end
    return reduce(vcat,dats)
end

function windowData(samp::Sample;blank=false,signal=false)
    if blank
        windows = samp.bwin
    elseif signal
        windows = samp.swin
    else
        windows = [(1,size(samp,1))]
    end
    selection = Integer[]
    for w in windows
        append!(selection, w[1]:w[2])
    end
    return samp.dat[selection,:]
end
