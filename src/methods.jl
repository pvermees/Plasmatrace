# helper functions
function label2index(pd::plasmaData,labels::Union{Nothing,Vector{String}})
    allabels = getLabels(pd)
    if isnothing(labels) return 1:size(allabels,1) end
    out = Vector{Int}(undef,0)
    for label in labels
        i = findfirst(in([label]),allabels)
        if !isnothing(i) push!(out,i) end
    end
    out
end
# get sample attributes from a run:
function accesSample(pd::run,
                     i::Union{Nothing,Int,Vector{Int}},
                     T::Type,
                     fun::Function)
    if isnothing(i) i = 1:length(pd) end
    samples = getSamples(pd)[i]
    if isa(i,Int)
        out = fun(samples)
    else
        out = Vector{T}(undef,size(i,1))
        for j in eachindex(samples)
            out[j] = fun(samples[j])
        end
    end
    out
end
function accessSample!(pd::run,
                       i::Union{Int,Vector{Int}},
                       fun::Function,val::Any)
    samples = getSamples(pd)
    for j in i fun(samples[j],val) end
    setSamples!(pd,samples)
end
# set the control parameters inside a run:
function accessControl!(pd::run,attribute::Symbol,fun::Function,val::Any)
    ctrl = getControl(pd)
    (ctrl,A)
    setControl(pd,ctrl)
end

# get sample attributes
function getSname(pd::sample) getproperty(pd,:sname) end
function getDateTime(pd::sample) getproperty(pd,:datetime) end
function getLabels(pd::sample) getproperty(pd,:labels) end
function getDat(pd::sample) getproperty(pd,:dat) end
function getBWin(pd::sample) getproperty(pd,:bwin) end
function getSWin(pd::sample) getproperty(pd,:swin) end
function getStandard(pd::sample) getproperty(pd,:standard) end
function getCols(pd::sample;labels) getDat(pd)[:,label2index(pd,labels)] end

# get run attributes
function getSamples(pd::run) getproperty(pd,:samples) end
function getControl(pd::run) getproperty(pd,:control) end
function getBPar(pd::run) getproperty(pd,:bpar) end
function getSPar(pd::run) getproperty(pd,:spar) end
function getBCov(pd::run) getproperty(pd,:bcov) end
function getSCov(pd::run) getproperty(pd,:scov) end

# get sample attributes from a run
function getSnames(pd::run;i=nothing) accesSample(pd,i,String,getSname) end
function getDateTimes(pd::run;i=nothing) accesSample(pd,i,DateTime,getDateTime) end
function getLabels(pd::run;i=1) out = accesSample(pd,i,Vector{String},getLabels) end
function getDat(pd::run;i=nothing) accesSample(pd,i,Matrix,getDat) end
function getBWin(pd::run;i=nothing) accesSample(pd,i,Vector{window},getBWin) end
function getSWin(pd::run;i=nothing) accesSample(pd,i,Vector{window},getSWin) end
function getStandard(pd::run;i=nothing) accesSample(pd,i,Int,getStandard) end

# get control attributes
function getA(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:A) end
function getB(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:B) end
function getChannels(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:channels) end

# get control attributes from a run
function getA(pd::run) getA(getControl(pd)) end
function getB(pd::run) getB(getControl(pd)) end
function getChannels(pd::run) getChannels(getControl(pd)) end

# set sample attributes
function setSname!(pd::sample;sname::String) setproperty!(pd,:sname,sname) end
function setDateTime!(pd::sample;datetime::DateTime) setproperty!(pd,:datetime,datetime) end
function setLabels!(pd::sample;labels::Vector{String}) setproperty!(pd,:labels,labels) end
function setDat!(pd::sample;dat::Matrix) setproperty!(pd,:dat,dat) end
function setBWin!(pd::sample;bwin::Vector{window}) setproperty!(pd,:bwin,bwin) end
function setSWin!(pd::sample;swin::Vector{window}) setproperty!(pd,:swin,swin) end
function setStandard!(pd::sample;standard::Int) setproperty!(pd,:standard,standard) end

# set run attributes
function setSamples!(pd::run;samples::Vector{sample}) setproperty!(pd,:samples,samples) end
function setControl!(pd::run;ctrl::control) setproperty!(pd,:control,ctrl) end
function setBPar!(pd::run;bpar::Vector) setproperty!(pd,:bpar,bpar) end
function setSPar!(pd::run;spar::Vector) setproperty!(pd,:spar,spar) end
function setBCov!(pd::run;bcov::Matrix) setproperty!(pd,:bcov,bcov) end
function setSCov!(pd::run;scov::Matrix) setproperty!(pd,:scov,scov) end

# set key sample attributes in a run
function setBWin!(pd::run;i,bwin::Vector{window}) accessSample!(pd,i,setBWin!,bwin) end
function setSWin!(pd::run;i,swin::Vector{window}) accessSample!(pd,i,setSWin!,bwin) end
function setStandard!(pd::run;i,standard::Int) accessSample!(pd,i,setStandard!,standard) end

# set control attributes
function setA!(ctrl::control;A::Vector{AbstractFloat}) setproperty!(pd,:A,A) end
function setB!(ctrl::control;B::Vector{AbstractFloat}) setproperty!(pd,:B,B) end
function setChannels!(ctrl::control;channels::Vector{String}) setproperty!(pd,:channels,channels) end

# set control attributes in a run
function setA!(pd::run;A::AbstractFloat) accessControl!(pd,:A,setA!,A) end
function setB!(pd::run;B::AbstractFloat) accessControl!(pd,:B,setB!,b) end
function setChannels!(pd::run;channels::Vector{String}) accessControl!(pd,:channels,setChannels!,channels) end

length(pd::run) = size(getSamples(pd),1)
ncol(pd::plasmaData) = size(getLabels(pd),1)

function poolRunDat(pd::run;i=nothing)
    dats = getDat(pd,i=i)
    reduce(vcat,dats)
end
