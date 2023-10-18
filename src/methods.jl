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
function getSName(pd::plasmaData) getproperty(getRaw(pd),:sname) end
function getLabels(pd::plasmaData) getproperty(getRaw(pd),:labels) end

function getIndex(pd::Union{RUN,run}) getproperty(getRaw(pd),:index) end

function getBWin(pd::processed) getproperty(pd,:bwin) end
function getSWin(pd::processed) getproperty(pd,:swin) end
function getBPar(pd::processed) getproperty(pd,:bpar) end
function getSPar(pd::processed) getproperty(pd,:spar) end
function getBCov(pd::processed) getproperty(pd,:bcov) end
function getSCov(pd::processed) getproperty(pd,:scov) end

function getControl(pd::processed) getproperty(pd,:control) end
function getControlPar(pd::processed,par)
    ctrl = getControl(pd)
    isnothing(ctrl) ? nothing : getproperty(ctrl,par)
end
function getA(pd::processed) getControlPar(pd,:A) end
function getB(pd::processed) getControlPar(pd,:B) end
function getChannels(pd::processed) getControlPar(pd,:channels) end

function setBlanks!(pd::processed;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=true)
end
function setSignals!(pd::processed;
                     windows::Union{Nothing,Vector{window}}=nothing,
                     i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=false)
end
function setBPar!(pd::processed,par::Vector) setproperty!(pd,:bpar,par) end
function setSPar!(pd::processed,par::Vector) setproperty!(pd,:spar,par) end
function setBCov!(pd::processed,cov::Vector) setproperty!(pd,:bcov,cov) end
function setSCov!(pd::processed,cov::Vector) setproperty!(pd,:scov,cov) end
function setControl!(pd::processed,ctrl::control) setproperty!(pd,:control,ctrl) end
function setChannels!(pd::processed,channels::Vector{String})
    ctrl = getControl(pd)
    if isnothing(ctrl) ctrl = control() end
    setproperty!(ctrl,:channels,channels)
    setControl!(pd,:control,ctrl)
end

length(pd::Union{RUN,run}) = Base.length(getSName(pd))
