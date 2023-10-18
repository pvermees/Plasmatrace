function getRaw(pd::raw)::raw pd end
function getRaw(pd::processed)::raw pd.data end

function getDat(pd::plasmaData)::Matrix getproperty(getRaw(pd),:dat) end
function getCols(pd::plasmaData;labels::Vector{String})::Matrix
    i = findall(in(labels).(getLabels(pd)))
    getDat(pd)[:,i]
end
function getVal(pd::plasmaData;r=1,c=1) getDat(pd)[r,c] end
function getDatetime(pd::plasmaData) getproperty(getRaw(pd),:datetime) end
function nsweeps(pd::plasmaData) size(getDat(pd),1) end
function getName(pd::plasmaData) getproperty(getRaw(pd),:sname) end
function getLabels(pd::plasmaData) getproperty(getRaw(pd),:labels) end

function getIndex(pd::Union{RUN,run}) getproperty(getRaw(pd),:index) end

function getBWin(pd::processed) getproperty(pd,:bwin) end
function getSWin(pd::processed) getproperty(pd,:swin) end
function getBPar(pd::processed) getproperty(pd,:bpar) end
function getSPar(pd::processed) getproperty(pd,:spar) end
function getBCov(pd::processed) getproperty(pd,:bcov) end
function getSCov(pd::processed) getproperty(pd,:scov) end

function getControl(pd::processed) getproperty(pd,:control) end
function getChannels(pd::processed)
    control = getControl(pd)
    isnothing(control) ? nothing : getproperty(control,:channels)
end

function setBlank!(pd::processed;
                   windows::Union{Nothing,Vector{window}}=nothing,
                   i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=true)
end
function setSignal!(pd::processed;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=false)
end
function setBPar!(pd::processed,par::Vector) getBPar(pd) = par end
function setSPar!(pd::processed,par::Vector) getSPar(pd) = par end
function setBCov!(pd::processed,cov::Vector) getBCov(pd) = cov end
function setSCov!(pd::processed,cov::Vector) getSCov(pd) = cov end
function setControl!(pd::processed,control::Tuple) getControl(pd) = control end
function setChannels!(pd::processed,channels::Vector{String})
    if isnothing(getControl(pd)) setControl!(control()) end
    getChannels(pd) = channels
end

length(pd::Union{RUN,run}) = Base.length(getName(pd))
