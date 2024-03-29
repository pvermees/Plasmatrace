function init_PT!()
    _PT["lambda"] = getLambda()
    _PT["iratio"] = getiratio()
    _PT["refmat"] = getReferenceMaterials()
end
export init_PT!

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
function setStandards!(run::Vector{Sample},standards::AbstractDict)
    for (refmat,prefix) in standards
        setStandards!(run,prefix,refmat)
    end
end
function setStandards!(run::Vector{Sample},refmat::AbstractString)
    for sample in run
        sample.group = refmat
    end
end
export setStandards!

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

function setBwin!(samp::Sample,bwin=nothing)
    if isnothing(bwin) bwin=autoWindow(samp,blank=true) end
    samp.bwin = bwin
end
function setBwin!(run::Vector{Sample},bwin=nothing)
    for i in eachindex(run)
        setBwin!(run[i],bwin)
    end
end
export setBwin!

function setSwin!(samp::Sample,swin=nothing)
    if isnothing(swin) swin=autoWindow(samp,blank=false) end
    samp.swin = swin
end
function setSwin!(run::Vector{Sample},swin=nothing)
    for i in eachindex(run)
        setSwin!(run[i],swin)
    end
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
export pool

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

function string2windows(samp::Sample;text::AbstractString,single=false)
    if single
        parts = split(text,',')
        stime = [parse(Float64,parts[1])]
        ftime = [parse(Float64,parts[2])]
        nw = 1
    else
        parts = split(text,['(',')',','])
        stime = parse.(Float64,parts[2:4:end])
        ftime = parse.(Float64,parts[3:4:end])
        nw = Int(round(size(parts,1)/4))
    end
    windows = Vector{Window}(undef,nw)
    t = samp.dat[:,2]
    nt = size(t,1)
    maxt = t[end]
    for i in 1:nw
        if stime[i]>t[end]
            stime[i] = t[end-1]
            print("Warning: start point out of bounds and truncated to ")
            print(string(stime[i]) * " seconds.")
        end
        if ftime[i]>t[end]
            ftime[i] = t[end]
            print("Warning: end point out of bounds and truncated to ")
            print(string(maxt) * " seconds.")
        end
        start = max(1,Int(round(nt*stime[i]/maxt)))
        finish = min(nt,Int(round(nt*ftime[i]/maxt)))
        windows[i] = (start,finish)
    end
    return windows
end

function getx0y0(method::AbstractString,refmat::AbstractString)
    L = _PT["lambda"][method][1]
    t = _PT["refmat"][method][refmat].t[1]
    x0 = 1/(exp(L*t)-1)
    y0 = _PT["refmat"][method][refmat].y0[1]
    return (x0=x0, y0=y0)
end

function getAnchor(method::AbstractString,refmat::AbstractString)
    if method=="LuHf"
        return getx0y0(method,refmat)
    end
end
function getAnchor(method::AbstractString,standards::Vector{String})
    nr = length(standards)
    out = Dict{String, NamedTuple}()
    for standard in standards
        out[standard] = getAnchor(method,standard)
    end
    return out
end
function getAnchor(method::AbstractString,standards::AbstractDict)
    return getAnchor(method,collect(keys(standards)))
end
export getAnchor

function setAnchor!(method::AbstractString,standards::AbstractDict)
    setMethod!(method)
    setStandards!(standards)
    setAnchor!()
end
function setAnchor!(method::AbstractString)
    setMethod!(method)
    setAnchor!()
end
export setAnchor!

function subset(run::Vector{Sample},selector::AbstractString)
    if length(selection)<1
        selection = findall(contains(prefix),getGroups(selector))
    end
    return run[selection]
end
function subset(ratios::AbstractDataFrame,prefix::AbstractString)
    return ratios[findall(contains(prefix),ratios[:,1]),:]
end
export subset

function getDat(samp::Sample)
    return samp.dat
end
function getDat(samp::Sample,channels::AbstractDict)
    return samp.dat[:,collect(values(channels))]
end
export getDat

function PAselect(run::Vector{Sample};channels::AbstractDict,cutoff::AbstractFloat)
    ns = length(run)
    A = fill(false,ns)
    for i in eachindex(A)
        dat = getDat(run[i],channels)
        A[i] = (false in Matrix(dat .< cutoff))
    end
    return A
end
export PAselect

function getLambda(csv::AbstractString=joinpath(@__DIR__,"../settings/lambda.csv"))
    tab = CSV.read(csv, DataFrame)
    out = Dict()
    for row in eachrow(tab)
        method = row["method"]
        out[method] = (row["lambda"],row["err"])
    end
    return out    
end
export getLambda
function getiratio(csv::AbstractString=joinpath(@__DIR__,"../settings/iratio.csv"))
    tab = CSV.read(csv, DataFrame)
    out = Dict()
    for row in eachrow(tab)
        isotope = row["isotope"]
        abundance = row["abundance"]
        method = row["method"]
        entry = NamedTuple{(Symbol(isotope),)}((abundance))
        if !(method in keys(out))
            out[method] = entry
        end
        out[method] = merge(out[method],entry)
    end
    return out    
end
export getiratio
function getReferenceMaterials(csv::AbstractString=joinpath(@__DIR__,"../settings/standards.csv"))
    tab = CSV.read(csv, DataFrame)
    out = Dict()
    for row in eachrow(tab)
        method = row["method"]
        if !(method in keys(out))
            out[method] = Dict()
        end
        name = row["name"]
        out[method][name] = (t=(row["t"],row["st"]),y0=(row["y0"],row["sy0"]))
    end
    return out    
end
function setReferenceMaterials!(csv::AbstractString=joinpath(@__DIR__,"../settings/standards.csv"))
    _PT["refmat"] = getReferenceMaterials!(csv)
end
export setReferenceMaterials!
